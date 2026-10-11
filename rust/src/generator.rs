use rand::Rng;
use crate::errors::{AppError, Result};

/// Массив строчных латинских букв.
const LOWERCASE: &[u8] = b"abcdefghijklmnopqrstuvwxyz";
/// Массив прописных латинских букв.
const UPPERCASE: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
/// Массив цифр.
const DIGITS: &[u8]    = b"0123456789";
/// Массив специальных символов.
const SYMBOLS: &[u8]   = b"!@#$%^&*()-_=+";
/// Минимальная допустимая длина пароля.
const MIN_LENGTH: usize = 8;
/// Максимальная допустимая длина пароля.
const MAX_LENGTH: usize = 128;

/// Генерирует случайный пароль.
///
/// # Аргументы
/// * `length` — длина генерируемого пароля.
/// * `use_symbols` — включать ли в пароль специальные символы.
///
/// # Возвращает
/// `Ok(String)` с новым паролем или ошибку, если длина некорректна.
pub fn generate(length: usize, use_symbols: bool) -> Result<String> {
    // Проверяем допустимую длину пароля
    if length < MIN_LENGTH || length > MAX_LENGTH {
        return Err(AppError::InputError(format!(
            "Длина должна быть от {} до {}",
            MIN_LENGTH, MAX_LENGTH
        )));
    }

    // Формируем набор допустимых символов
    // Базовый набор: строчные + прописные + цифры
    let mut charset: Vec<u8> = Vec::with_capacity(
        LOWERCASE.len() + UPPERCASE.len() + DIGITS.len() + SYMBOLS.len()
    );
    charset.extend_from_slice(LOWERCASE);
    charset.extend_from_slice(UPPERCASE);
    charset.extend_from_slice(DIGITS);

    // Если запрошено, добавляем специальные символы
    if use_symbols {
        charset.extend_from_slice(SYMBOLS);
    }

    // Инициализируем генератор случайных чисел
    let mut rng = rand::thread_rng();

    // Создаём строку заданной длины
    let mut password = String::with_capacity(length);
    for _ in 0..length {
        // Выбираем случайный символ из набора
        let idx = rng.gen_range(0..charset.len());
        password.push(charset[idx] as char);
    }

    Ok(password)
}

/// Оценка надёжности пароля: "слабый", "средний", "сильный".
pub fn strength(password: &str) -> &'static str {
    let len = password.len();
    let has_lower = password.chars().any(|c| c.is_ascii_lowercase());
    let has_upper = password.chars().any(|c| c.is_ascii_uppercase());
    let has_digit = password.chars().any(|c| c.is_ascii_digit());
    let has_symbol = password.chars().any(|c| !c.is_alphanumeric());

    let variety = [has_lower, has_upper, has_digit, has_symbol]
        .iter()
        .filter(|&&x| x)
        .count();

    if len >= 12 && variety >= 3 {
        "сильный"
    } else if len >= 8 && variety >= 2 {
        "средний"
    } else {
        "слабый"
    }
}