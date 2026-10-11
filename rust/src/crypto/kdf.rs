use argon2::{Argon2, Algorithm, Version, Params};
use rand::RngCore;
use crate::errors::{AppError, Result};

/// Генерирует случайную соль размером 16 байт.
pub fn generate_salt() -> [u8; 16] {
    let mut salt = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut salt);
    salt
}

/// Выводит криптографический ключ из пароля и соли, используя алгоритм Argon2.
pub fn derive_key(password: &str, salt: &[u8]) -> Result<[u8; 32]> {
    // Параметры Argon2:
    // memory_cost: 64 МБ (65536 КБ)
    // time_cost: 3 прохода
    // parallelism: 4 потока
    // output_len: 32 байта
    let params = Params::new(65536, 3, 4, Some(32))
        .map_err(|e| AppError::Crypto(format!("Params error: {}", e)))?;
    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);

    let mut key = [0u8; 32];
    argon2
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .map_err(|e| AppError::Crypto(format!("Argon2 error: {}", e)))?;

    Ok(key)
}