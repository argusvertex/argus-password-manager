use serde::{Serialize, Deserialize};

/// Структура, хранящая глобальные настройки приложения.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Config {
    /// Версия формата файла хранилища.
    pub version: u32,
    /// Время бездействия до автоматической блокировки (в минутах).
    pub autolock_minutes: u32,
    /// Тема интерфейса ("dark" или "light").
    pub theme: String,
    /// Соль для настоящего хранилища (Base64).
    pub salt: String,
    /// Соль для ложного (duress) хранилища (Base64). None — не установлено.
    #[serde(default)]
    pub decoy_salt: Option<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            version: 1,
            autolock_minutes: 5,
            theme: "dark".to_string(),
            salt: String::new(),
            decoy_salt: None,
        }
    }
}

impl Config {
    /// Создаёт конфиг с заданной солью настоящего хранилища.
    pub fn new(salt: String) -> Self {
        let mut config = Self::default();
        config.salt = salt;
        config
    }

    /// Устанавливает соль для ложного хранилища.
    pub fn set_decoy_salt(&mut self, salt: String) {
        self.decoy_salt = Some(salt);
    }

    /// Убирает соль duress-пароля.
    pub fn clear_decoy_salt(&mut self) {
        self.decoy_salt = None;
    }
}