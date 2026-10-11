use serde::{Serialize, Deserialize};

/// Структура для одной записи пароля.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PasswordEntry {
    pub id: u64,
    pub service: String,
    pub username: String,
    pub password: String,
    pub note: String,
    pub created_at: u64,   // Unix timestamp (секунды)
    pub updated_at: u64,   // Unix timestamp (секунды)
    #[serde(default)]
    pub folder_id: Option<u64>,
}

impl PasswordEntry {
    /// Создаёт новую запись пароля.
    /// Инициализирует поля created_at и updated_at текущим Unix timestamp.
    pub fn new(id: u64, service: String, username: String, password: String, note: String) -> Self {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        Self {
            id,
            service,
            username,
            password,
            note,
            created_at: now,
            updated_at: now,
            folder_id: None,
        }
    }

    /// Возвращает true, если query (в нижнем регистре) содержится в service, username или note.
    /// Сравнение происходит без учёта регистра.
    pub fn matches(&self, query: &str) -> bool {
        let query_lower = query.to_lowercase();
        self.service.to_lowercase().contains(&query_lower)
            || self.username.to_lowercase().contains(&query_lower)
            || self.note.to_lowercase().contains(&query_lower)
    }

    /// Обновляет поле updated_at текущим временем.
    pub fn touch(&mut self) {
        self.updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);
    }
}