# Authentication Feature (Clean Architecture + BLoC)

Complete production authentication flow implemented in Step 2:

```
features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart      # Dio HTTP calls to FastAPI /auth/*
│   ├── models/
│   │   ├── auth_request_models.dart         # Login & Register DTOs
│   │   ├── auth_token_model.dart            # Token pair + expires_in DTO
│   │   └── auth_user_model.dart             # Safe User DTO
│   └── repositories/
│       └── auth_repository_impl.dart        # Result-wrapped repository with token storage
├── domain/
│   ├── entities/
│   │   ├── auth_token.dart                  # Domain token entity
│   │   └── auth_user.dart                   # Domain user entity
│   ├── repositories/
│   │   └── auth_repository.dart             # Abstract interface contract
│   └── usecases/
│       ├── check_auth_status_usecase.dart   # Verify stored token
│       ├── get_current_user_usecase.dart    # GET /auth/me profile
│       ├── login_usecase.dart               # Credentials authentication
│       ├── logout_usecase.dart              # Stateless wipe session
│       ├── refresh_token_usecase.dart       # Access token renewal
│       └── register_usecase.dart            # Account registration
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                   # Central state machine
    │   ├── auth_event.dart                  # Check, Login, Register, Logout, Refresh
    │   └── auth_state.dart                  # Initial, Loading, Authenticated, Unauthenticated, Failure
    ├── pages/
    │   ├── login_page.dart                  # High-end login UI with validation
    │   └── register_page.dart               # High-end registration with strength meter & role card selector
    └── widgets/
        ├── password_strength_bar.dart       # Live 4-tier strength meter
        ├── role_selector.dart               # Buyer vs Seller cards
        └── social_login_buttons.dart        # Visual preview social buttons
```
