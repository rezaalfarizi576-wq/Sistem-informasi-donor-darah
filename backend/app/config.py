from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Semua konfigurasi diambil dari file .env.
    Lihat .env.example untuk daftar variabel yang dibutuhkan.
    """

    app_name: str = "Donor Darah Lamongan API"
    app_env: str = "development"
    debug: bool = True
    port: int = 8000
    host: str = "0.0.0.0"

    db_host: str = "localhost"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = ""
    db_name: str = "donor_darah_lamongan"

    secret_key: str = "change_this_to_a_very_secure_secret_key_in_production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Mock PMI API
    pmi_api_base_url: str = "http://localhost:8001"
    pmi_api_key: str = "dummy-pmi-secret-key"

    @property
    def database_url(self) -> str:
        password_part = f":{self.db_password}" if self.db_password else ""
        return (
            f"mysql+pymysql://{self.db_user}{password_part}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    # Aliases for compatibility
    @property
    def APP_NAME(self) -> str:
        return self.app_name

    @property
    def APP_ENV(self) -> str:
        return self.app_env

    @property
    def DEBUG(self) -> bool:
        return self.debug

    @property
    def SECRET_KEY(self) -> str:
        return self.secret_key

    @property
    def ALGORITHM(self) -> str:
        return self.algorithm

    @property
    def ACCESS_TOKEN_EXPIRE_MINUTES(self) -> int:
        return self.access_token_expire_minutes

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
