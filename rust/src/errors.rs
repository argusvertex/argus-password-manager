use thiserror::Error;

/// Основной тип ошибок для проекта
#[derive(Debug, Error)]
pub enum AppError {
    /// Ошибка ввода-вывода
    #[error("Ошибка ввода-вывода: {0}")]
    Io(#[from] std::io::Error),

    /// Ошибка сериализации
    #[error("Ошибка сериализации: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Ошибка шифрования
    #[error("Ошибка шифрования: {0}")]
    Crypto(String),

    /// Неверный мастер-пароль
    #[error("Неверный мастер-пароль")]
    InvalidPassword,

    /// Хранилище не найдено
    #[error("Хранилище не найдено. Создайте новое.")]
    VaultNotFound,

    /// Хранилище уже существует
    #[error("Хранилище уже существует")]
    VaultAlreadyExists,

    /// Запись не найдена
    #[error("Запись с id={0} не найдена")]
    EntryNotFound(u64),

    /// Достигнут лимит записей
    #[error("Достигнут лимит записей ({0}). Купите Pro версию.")]
    LimitExceeded(usize),

    /// Ошибка ввода
    #[error("Ошибка ввода: {0}")]
    InputError(String),
}

/// Публичный алиас для Result
pub type Result<T> = std::result::Result<T, AppError>;