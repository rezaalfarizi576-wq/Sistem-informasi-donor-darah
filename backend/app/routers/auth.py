# Alias router for app.routers.auth
from app.routers.auth_router import (
    router,
    register,
    activate_account,
    login,
    read_current_user,
)

__all__ = ["router", "register", "activate_account", "login", "read_current_user"]
