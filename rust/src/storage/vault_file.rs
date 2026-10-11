use std::fs;
use super::paths;
use crate::models::{Vault, Config};
use crate::crypto::cipher;
use crate::errors::{AppError, Result};

/// Сохраняет хранилище (Vault) в зашифрованном виде на диск.
/// Использует переданный ключ для шифрования данных.
pub fn save_vault(vault: &Vault, key: &[u8; 32]) -> Result<()> {
    // Сериализуем хранилище в JSON
    let json = serde_json::to_vec(vault)?;

    // Шифруем полученные байты
    let encrypted = cipher::encrypt(&json, key)?;

    // Записываем зашифрованные данные в файл
    fs::write(paths::vault_path(), encrypted)?;

    Ok(())
}

/// Загружает и расшифровывает хранилище (Vault) с диска.
/// Возвращает ошибку AppError::VaultNotFound, если файл не существует.
pub fn load_vault(key: &[u8; 32]) -> Result<Vault> {
    // Проверяем, существует ли файл хранилища
    if !paths::vault_path().exists() {
        return Err(AppError::VaultNotFound);
    }

    // Читаем зашифрованные данные из файла
    let encrypted = fs::read(paths::vault_path())?;

    // Расшифровываем данные
    let json = cipher::decrypt(&encrypted, key)?;

    // Десериализуем JSON в структуру Vault
    let vault: Vault = serde_json::from_slice(&json)?;

    Ok(vault)
}

/// Проверяет, существует ли файл хранилища на диске.
pub fn vault_exists() -> bool {
    paths::vault_path().exists()
}

/// Сохраняет конфигурацию (Config) в JSON-файл на диск.
pub fn save_config(config: &Config) -> Result<()> {
    // Сериализуем конфигурацию в pretty JSON
    let json = serde_json::to_string_pretty(config)?;

    // Записываем данные в файл
    fs::write(paths::config_path(), json)?;

    Ok(())
}

/// Загружает конфигурацию (Config) с диска.
/// Если файл не существует, возвращает конфигурацию по умолчанию.
pub fn load_config() -> Result<Config> {
    let config_path = paths::config_path();

    // Если файл не существует, возвращаем конфигурацию по умолчанию
    if !config_path.exists() {
        return Ok(Config::default());
    }

    // Читаем файл
    let json = fs::read_to_string(config_path)?;

    // Парсим JSON
    let config: Config = serde_json::from_str(&json)?;

    Ok(config)
}
/// Сохраняет ложное (duress) хранилище на диск.
pub fn save_decoy(vault: &Vault, key: &[u8; 32]) -> Result<()> {
    let json = serde_json::to_vec(vault)?;
    let encrypted = cipher::encrypt(&json, key)?;
    fs::write(paths::decoy_path(), encrypted)?;
    Ok(())
}

/// Загружает и расшифровывает ложное хранилище.
pub fn load_decoy(key: &[u8; 32]) -> Result<Vault> {
    if !paths::decoy_path().exists() {
        return Err(AppError::VaultNotFound);
    }
    let encrypted = fs::read(paths::decoy_path())?;
    let json = cipher::decrypt(&encrypted, key)?;
    let vault: Vault = serde_json::from_slice(&json)?;
    Ok(vault)
}

/// Проверяет, существует ли файл ложного хранилища.
pub fn decoy_exists() -> bool {
    paths::decoy_path().exists()
}