use std::path::PathBuf;
use std::fs;
use dirs;

// Имя папки приложения в директории конфигурации
const APP_DIR_NAME: &str = "password-manager";
// Имя файла зашифрованного хранилища
const VAULT_FILENAME: &str = "vault.enc";

const DECOY_FILENAME: &str = "decoy.enc";
// Имя файла конфигурации
const CONFIG_FILENAME: &str = "config.json";

/// Возвращает путь к директории, где хранятся файлы приложения.
/// Создаёт директорию, если она не существует.
pub fn vault_dir() -> PathBuf {
    // Получаем путь к папке конфигурации пользователя
    // Если не удалось определить (например, на Windows без профиля), используем текущую директорию
    let mut path = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."));
    
    // Добавляем имя папки приложения
    path.push(APP_DIR_NAME);
    
    // Создаём директорию, если её нет. Игнорируем ошибку, если она уже существует.
    fs::create_dir_all(&path).ok();
    
    path
}

/// Возвращает полный путь к файлу зашифрованного хранилища (vault.enc).
pub fn vault_path() -> PathBuf {
    vault_dir().join(VAULT_FILENAME)
}

/// Возвращает полный путь к файлу конфигурации (config.json).
pub fn config_path() -> PathBuf {
    vault_dir().join(CONFIG_FILENAME)
}
/// Возвращает полный путь к файлу ложного (duress) хранилища.
pub fn decoy_path() -> PathBuf {
    vault_dir().join(DECOY_FILENAME)
}