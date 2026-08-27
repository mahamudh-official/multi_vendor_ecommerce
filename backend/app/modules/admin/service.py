"""
Business logic service for platform administration, seller moderation, and audit management.
"""
import re
import uuid
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.admin.repository import AdminRepository
from app.modules.admin.schemas import (
    AdminCategoryCreate,
    AdminCategoryListResponse,
    AdminCategoryRead,
    AdminCategoryUpdate,
    AdminDashboardStats,
    AdminOrderItemRead,
    AdminOrderListResponse,
    AdminOrderRead,
    AdminPaymentListResponse,
    AdminPaymentRead,
    AdminProductListResponse,
    AdminProductRead,
    AdminSellerListResponse,
    AdminSellerRead,
    AdminSellerUpdateStatus,
    AdminUserListResponse,
    AdminUserRead,
)
from app.modules.audit.service import AuditService
from app.modules.auth.models import SellerStatus, User, UserRole
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import NotificationService
from app.modules.products.models import Category, Product


class AdminService:
    def __init__(
        self,
        repository: AdminRepository,
        audit_service: AuditService,
        notification_service: NotificationService,
        session: AsyncSession,
    ) -> None:
        self.repository = repository
        self.audit_service = audit_service
        self.notification_service = notification_service
        self.session = session

    # ── 1. Dashboard Metrics ──────────────────────────────────────────────────

    async def get_dashboard_stats(self) -> AdminDashboardStats:
        data = await self.repository.get_dashboard_metrics()
        return AdminDashboardStats(**data)

    # ── 2. User Management ────────────────────────────────────────────────────

    async def list_users(
        self,
        search: Optional[str] = None,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AdminUserListResponse:
        users, total = await self.repository.list_users(
            search=search,
            role=role,
            is_active=is_active,
            page=page,
            page_size=page_size,
        )
        return AdminUserListResponse(
            items=[AdminUserRead.model_validate(u) for u in users],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_user_details(self, user_id: uuid.UUID) -> AdminUserRead:
        user = await self.repository.get_user_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )
        return AdminUserRead.model_validate(user)

    async def update_user_status(
        self,
        admin_user: User,
        user_id: uuid.UUID,
        is_active: bool,
    ) -> AdminUserRead:
        # Prevent admin from deactivating their own account
        if admin_user.id == user_id and not is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Administrators cannot deactivate their own active account.",
            )

        user = await self.repository.get_user_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        prev_status = user.is_active
        user.is_active = is_active
        await self.session.commit()
        await self.session.refresh(user)

        action = "user_activated" if is_active else "user_deactivated"
        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action=action,
            entity_type="user",
            entity_id=str(user.id),
            metadata={
                "email": user.email,
                "previous_is_active": prev_status,
                "new_is_active": is_active,
            },
        )
        await self.session.commit()

        return AdminUserRead.model_validate(user)

    # ── 3. Seller Management ──────────────────────────────────────────────────

    async def list_sellers(
        self,
        search: Optional[str] = None,
        seller_status: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AdminSellerListResponse:
        sellers, total = await self.repository.list_sellers(
            search=search,
            seller_status=seller_status,
            page=page,
            page_size=page_size,
        )
        return AdminSellerListResponse(
            items=[AdminSellerRead(**s) for s in sellers],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def update_seller_status(
        self,
        admin_user: User,
        seller_id: uuid.UUID,
        target_status: str,
    ) -> AdminSellerRead:
        target_status_clean = target_status.strip().lower()
        if target_status_clean not in [SellerStatus.approved.value, SellerStatus.suspended.value]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Target status must be either 'approved' or 'suspended'.",
            )

        seller = await self.repository.get_user_by_id(seller_id)
        if not seller or seller.role != UserRole.seller:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Seller not found.",
            )

        current_status = seller.seller_status or SellerStatus.approved.value

        # Validate state machine transitions
        # pending -> approved
        # approved -> suspended
        # suspended -> approved
        valid_transition = (
            (current_status == SellerStatus.pending.value and target_status_clean == SellerStatus.approved.value)
            or (current_status == SellerStatus.approved.value and target_status_clean == SellerStatus.suspended.value)
            or (current_status == SellerStatus.suspended.value and target_status_clean == SellerStatus.approved.value)
            or (current_status == target_status_clean)  # idempotent no-op
        )

        if not valid_transition:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid seller transition from '{current_status}' to '{target_status_clean}'.",
            )

        seller.seller_status = target_status_clean
        await self.session.commit()
        await self.session.refresh(seller)

        # Notify seller
        if target_status_clean == SellerStatus.approved.value:
            await self.notification_service.send_notification(
                user_id=seller.id,
                type=NotificationType.ORDER_CONFIRMED,
                title="Seller Account Approved",
                message="Your seller account has been approved. You can now manage products and process orders.",
                data={"seller_id": str(seller.id), "status": "approved"},
            )
            action = "seller_approved"
        else:
            await self.notification_service.send_notification(
                user_id=seller.id,
                type=NotificationType.ORDER_CANCELLED,
                title="Seller Account Suspended",
                message="Your seller account has been suspended by platform administration.",
                data={"seller_id": str(seller.id), "status": "suspended"},
            )
            action = "seller_suspended"

        # Log audit
        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action=action,
            entity_type="seller",
            entity_id=str(seller.id),
            metadata={
                "seller_email": seller.email,
                "previous_status": current_status,
                "new_status": target_status_clean,
            },
        )
        await self.session.commit()

        sellers, _ = await self.repository.list_sellers(search=seller.email, page=1, page_size=1)
        if sellers:
            return AdminSellerRead(**sellers[0])
        return AdminSellerRead(
            id=seller.id,
            full_name=seller.full_name,
            email=seller.email,
            seller_status=seller.seller_status,
            is_active=seller.is_active,
            created_at=seller.created_at,
        )

    # ── 4. Product Moderation ─────────────────────────────────────────────────

    async def list_products(
        self,
        seller_id: Optional[uuid.UUID] = None,
        category_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        low_stock: Optional[bool] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AdminProductListResponse:
        products, total = await self.repository.list_products(
            seller_id=seller_id,
            category_id=category_id,
            is_active=is_active,
            low_stock=low_stock,
            search=search,
            page=page,
            page_size=page_size,
        )

        items = []
        for p in products:
            items.append(
                AdminProductRead(
                    id=p.id,
                    seller_id=p.seller_id,
                    seller_name=p.seller.full_name if p.seller else None,
                    category_id=p.category_id,
                    category_name=p.category.name if p.category else None,
                    name=p.name,
                    slug=p.slug,
                    description=p.description,
                    price=p.price,
                    compare_at_price=p.compare_at_price,
                    stock_quantity=p.stock_quantity,
                    sku=p.sku,
                    image_url=p.image_url,
                    is_active=p.is_active,
                    is_featured=p.is_featured,
                    created_at=p.created_at,
                    updated_at=p.updated_at,
                )
            )

        return AdminProductListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_product_details(self, product_id: uuid.UUID) -> AdminProductRead:
        p = await self.repository.get_product_by_id(product_id)
        if not p:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found.",
            )
        return AdminProductRead(
            id=p.id,
            seller_id=p.seller_id,
            seller_name=p.seller.full_name if p.seller else None,
            category_id=p.category_id,
            category_name=p.category.name if p.category else None,
            name=p.name,
            slug=p.slug,
            description=p.description,
            price=p.price,
            compare_at_price=p.compare_at_price,
            stock_quantity=p.stock_quantity,
            sku=p.sku,
            image_url=p.image_url,
            is_active=p.is_active,
            is_featured=p.is_featured,
            created_at=p.created_at,
            updated_at=p.updated_at,
        )

    async def update_product_status(
        self,
        admin_user: User,
        product_id: uuid.UUID,
        is_active: bool,
    ) -> AdminProductRead:
        p = await self.repository.get_product_by_id(product_id)
        if not p:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found.",
            )

        prev_is_active = p.is_active
        p.is_active = is_active
        await self.session.commit()
        await self.session.refresh(p)

        action = "product_activated" if is_active else "product_deactivated"
        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action=action,
            entity_type="product",
            entity_id=str(p.id),
            metadata={
                "product_name": p.name,
                "previous_is_active": prev_is_active,
                "new_is_active": is_active,
            },
        )
        await self.session.commit()

        return await self.get_product_details(product_id)

    # ── 5. Category Management ────────────────────────────────────────────────

    async def list_categories(self) -> AdminCategoryListResponse:
        cats = await self.repository.list_categories_with_product_count()
        return AdminCategoryListResponse(
            items=[AdminCategoryRead(**c) for c in cats],
            total=len(cats),
        )

    async def create_category(
        self,
        admin_user: User,
        data: AdminCategoryCreate,
    ) -> AdminCategoryRead:
        slug = data.slug or re.sub(r"[\s_-]+", "-", re.sub(r"[^a-zA-Z0-9\s-]", "", data.name).strip().lower())
        category = Category(
            id=uuid.uuid4(),
            name=data.name,
            slug=slug,
            description=data.description,
            image_url=data.image_url,
            is_active=data.is_active,
        )
        self.session.add(category)
        try:
            await self.session.commit()
            await self.session.refresh(category)
        except Exception:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category name or slug already exists.",
            )

        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action="category_created",
            entity_type="category",
            entity_id=str(category.id),
            metadata={"name": category.name, "slug": category.slug},
        )
        await self.session.commit()

        return AdminCategoryRead(
            id=category.id,
            name=category.name,
            slug=category.slug,
            description=category.description,
            image_url=category.image_url,
            is_active=category.is_active,
            product_count=0,
            created_at=category.created_at,
            updated_at=category.updated_at,
        )

    async def update_category(
        self,
        admin_user: User,
        category_id: uuid.UUID,
        data: AdminCategoryUpdate,
    ) -> AdminCategoryRead:
        cat = await self.repository.get_category_by_id(category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if data.name is not None:
            cat.name = data.name
        if data.slug is not None:
            cat.slug = data.slug
        if data.description is not None:
            cat.description = data.description
        if data.image_url is not None:
            cat.image_url = data.image_url
        if data.is_active is not None:
            cat.is_active = data.is_active

        try:
            await self.session.commit()
            await self.session.refresh(cat)
        except Exception:
            await self.session.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category name or slug already exists.",
            )

        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action="category_updated",
            entity_type="category",
            entity_id=str(cat.id),
            metadata={"name": cat.name, "is_active": cat.is_active},
        )
        await self.session.commit()

        prod_count = await self.repository.count_category_products(cat.id)
        return AdminCategoryRead(
            id=cat.id,
            name=cat.name,
            slug=cat.slug,
            description=cat.description,
            image_url=cat.image_url,
            is_active=cat.is_active,
            product_count=prod_count,
            created_at=cat.created_at,
            updated_at=cat.updated_at,
        )

    async def delete_category(
        self,
        admin_user: User,
        category_id: uuid.UUID,
    ) -> Dict[str, Any]:
        cat = await self.repository.get_category_by_id(category_id)
        if not cat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        prod_count = await self.repository.count_category_products(category_id)
        if prod_count > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete category with {prod_count} associated product(s). Please deactivate it instead.",
            )

        await self.session.delete(cat)
        await self.session.commit()

        await self.audit_service.log_action(
            admin_user_id=admin_user.id,
            action="category_deleted",
            entity_type="category",
            entity_id=str(category_id),
            metadata={"deleted_category_name": cat.name},
        )
        await self.session.commit()

        return {"message": f"Category '{cat.name}' deleted successfully."}

    # ── 6. Order Management ──────────────────────────────────────────────────

    async def list_orders(
        self,
        status: Optional[str] = None,
        payment_status: Optional[str] = None,
        customer_id: Optional[uuid.UUID] = None,
        seller_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AdminOrderListResponse:
        orders, total = await self.repository.list_orders(
            status=status,
            payment_status=payment_status,
            customer_id=customer_id,
            seller_id=seller_id,
            page=page,
            page_size=page_size,
        )

        items = []
        for o in orders:
            seller_ids = list({item.seller_id for item in o.items})
            order_items = [
                AdminOrderItemRead(
                    id=item.id,
                    product_id=item.product_id,
                    seller_id=item.seller_id,
                    seller_name=None,
                    product_name=item.product_name,
                    product_sku=item.product_sku,
                    product_image_url=item.product_image_url,
                    unit_price=item.unit_price,
                    quantity=item.quantity,
                    line_total=item.line_total,
                    fulfillment_status=item.fulfillment_status,
                )
                for item in o.items
            ]

            items.append(
                AdminOrderRead(
                    id=o.id,
                    user_id=o.user_id,
                    customer_email=o.user.email if o.user else None,
                    customer_name=o.user.full_name if o.user else None,
                    order_number=o.order_number,
                    status=o.status,
                    payment_status=o.payment_status,
                    subtotal=o.subtotal,
                    shipping_fee=o.shipping_fee,
                    discount_amount=o.discount_amount,
                    tax_amount=o.tax_amount,
                    total_amount=o.total_amount,
                    currency=o.currency,
                    shipping_full_name=o.shipping_full_name,
                    shipping_phone=o.shipping_phone,
                    shipping_address_line1=o.shipping_address_line1,
                    shipping_address_line2=o.shipping_address_line2,
                    shipping_city=o.shipping_city,
                    shipping_state=o.shipping_state,
                    shipping_postal_code=o.shipping_postal_code,
                    shipping_country=o.shipping_country,
                    customer_note=o.customer_note,
                    created_at=o.created_at,
                    items=order_items,
                    seller_count=len(seller_ids),
                )
            )

        return AdminOrderListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_order_details(self, order_id: uuid.UUID) -> AdminOrderRead:
        o = await self.repository.get_order_by_id(order_id)
        if not o:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        seller_ids = list({item.seller_id for item in o.items})
        order_items = [
            AdminOrderItemRead(
                id=item.id,
                product_id=item.product_id,
                seller_id=item.seller_id,
                seller_name=None,
                product_name=item.product_name,
                product_sku=item.product_sku,
                product_image_url=item.product_image_url,
                unit_price=item.unit_price,
                quantity=item.quantity,
                line_total=item.line_total,
                fulfillment_status=item.fulfillment_status,
            )
            for item in o.items
        ]

        return AdminOrderRead(
            id=o.id,
            user_id=o.user_id,
            customer_email=o.user.email if o.user else None,
            customer_name=o.user.full_name if o.user else None,
            order_number=o.order_number,
            status=o.status,
            payment_status=o.payment_status,
            subtotal=o.subtotal,
            shipping_fee=o.shipping_fee,
            discount_amount=o.discount_amount,
            tax_amount=o.tax_amount,
            total_amount=o.total_amount,
            currency=o.currency,
            shipping_full_name=o.shipping_full_name,
            shipping_phone=o.shipping_phone,
            shipping_address_line1=o.shipping_address_line1,
            shipping_address_line2=o.shipping_address_line2,
            shipping_city=o.shipping_city,
            shipping_state=o.shipping_state,
            shipping_postal_code=o.shipping_postal_code,
            shipping_country=o.shipping_country,
            customer_note=o.customer_note,
            created_at=o.created_at,
            items=order_items,
            seller_count=len(seller_ids),
        )

    # ── 7. Payment Monitoring ─────────────────────────────────────────────────

    async def list_payments(
        self,
        status: Optional[str] = None,
        provider: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> AdminPaymentListResponse:
        payments, total = await self.repository.list_payments(
            status=status,
            provider=provider,
            page=page,
            page_size=page_size,
        )

        items = [
            AdminPaymentRead(
                id=p.id,
                order_id=p.order_id,
                order_number=p.order.order_number if p.order else None,
                user_id=p.user_id,
                customer_email=p.user.email if p.user else None,
                amount=p.amount,
                currency=p.currency,
                status=p.status,
                provider=p.provider,
                provider_payment_id=p.provider_payment_id,
                created_at=p.created_at,
                updated_at=p.updated_at,
            )
            for p in payments
        ]

        return AdminPaymentListResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_payment_details(self, payment_id: uuid.UUID) -> AdminPaymentRead:
        p = await self.repository.get_payment_by_id(payment_id)
        if not p:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found.",
            )

        return AdminPaymentRead(
            id=p.id,
            order_id=p.order_id,
            order_number=p.order.order_number if p.order else None,
            user_id=p.user_id,
            customer_email=p.user.email if p.user else None,
            amount=p.amount,
            currency=p.currency,
            status=p.status,
            provider=p.provider,
            provider_payment_id=p.provider_payment_id,
            created_at=p.created_at,
            updated_at=p.updated_at,
        )
