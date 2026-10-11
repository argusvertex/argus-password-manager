use chacha20poly1305::{
    ChaCha20Poly1305, Key, Nonce,
    aead::{Aead, KeyInit, OsRng, AeadCore},
};
use crate::errors::{AppError, Result};

/// Размер nonce в байтах.
const NONCE_SIZE: usize = 12;

/// Шифрует текст (plaintext) с использованием ключа.
/// Возвращает вектор байт, содержащий nonce (12 байт) и зашифрованные данные.
pub fn encrypt(plaintext: &[u8], key: &[u8; 32]) -> Result<Vec<u8>> {
    // Создаём шифр из ключа
    let cipher = ChaCha20Poly1305::new(Key::from_slice(key));

    // Генерируем случайный nonce
    let nonce = ChaCha20Poly1305::generate_nonce(&mut OsRng);

    // Шифруем данные
    let ciphertext = cipher.encrypt(&nonce, plaintext).map_err(|e| {
        AppError::Crypto(format!("Encryption error: {}", e))
    })?;

    // Формируем результат: nonce + ciphertext
    let mut result = Vec::with_capacity(NONCE_SIZE + ciphertext.len());
    result.extend_from_slice(nonce.as_slice());
    result.extend_from_slice(&ciphertext);

    Ok(result)
}

/// Расшифровывает данные (data) с использованием ключа.
/// Ожидается, что data начинается с nonce (12 байт).
pub fn decrypt(data: &[u8], key: &[u8; 32]) -> Result<Vec<u8>> {
    // Проверяем минимальную длину данных
    if data.len() < NONCE_SIZE {
        return Err(AppError::Crypto("Data too short".into()));
    }

    // Разделяем nonce и зашифрованные данные
    let nonce = Nonce::from_slice(&data[..NONCE_SIZE]);
    let ciphertext = &data[NONCE_SIZE..];

    // Создаём шифр
    let cipher = ChaCha20Poly1305::new(Key::from_slice(key));

    // Расшифровываем данные
    let plaintext = cipher.decrypt(nonce, ciphertext).map_err(|e| {
        AppError::Crypto(format!("Decryption error: {}", e))
    })?;

    Ok(plaintext)
}