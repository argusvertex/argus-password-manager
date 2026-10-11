use crate::models::{Vault, Config};
use crate::models::entry::PasswordEntry;
use crate::crypto::kdf;
use crate::storage::{paths, vault_file};
use crate::core::session::{Session, Mode};
use crate::errors::{AppError, Result};
use base64::{Engine as _, engine::general_purpose::STANDARD};

/// Максимальное количество записей для бесплатной версии.
pub const FREE_LIMIT: usize = 30;

/// Создаёт новое зашифрованное хранилище.
pub fn create_vault(master_password: &str) -> Result<Session> {
    if vault_file::vault_exists() {
        return Err(AppError::VaultAlreadyExists);
    }

    let salt = kdf::generate_salt();
    let salt_b64 = STANDARD.encode(salt);
    let config = Config::new(salt_b64);
    vault_file::save_config(&config)?;

    let key = kdf::derive_key(master_password, &salt)?;
    let vault = Vault::new();
    vault_file::save_vault(&vault, &key)?;

    let mut session = Session::new_locked(config);
    session.unlock(key, vault, Mode::Real);
    Ok(session)
}


/// потом (если есть) — duress-пароль.
pub fn unlock_vault(password: &str) -> Result<Session> {
    let config = vault_file::load_config()?;

    if config.salt.is_empty() {
        return Err(AppError::VaultNotFound);
    }

    // Попытка 1: настоящий пароль
    let real_salt = STANDARD
        .decode(&config.salt)
        .map_err(|e| AppError::Crypto(format!("Base64 error: {}", e)))?;
    let real_key = kdf::derive_key(password, &real_salt)?;

    if let Ok(vault) = vault_file::load_vault(&real_key) {
        let mut session = Session::new_locked(config);
        session.unlock(real_key, vault, Mode::Real);
        return Ok(session);
    }

    // Попытка 2: duress-пароль (если установлен)
    if let Some(ref decoy_salt_b64) = config.decoy_salt {
        let decoy_salt = STANDARD
            .decode(decoy_salt_b64)
            .map_err(|e| AppError::Crypto(format!("Base64 error: {}", e)))?;
        let decoy_key = kdf::derive_key(password, &decoy_salt)?;

        if let Ok(vault) = vault_file::load_decoy(&decoy_key) {
            let mut session = Session::new_locked(config);
            session.unlock(decoy_key, vault, Mode::Duress);
            return Ok(session);
        }
    }

    Err(AppError::InvalidPassword)
}

/// Сохраняет текущее хранилище в правильный файл (vault.enc или decoy.enc).
pub fn save_session(session: &Session) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let key = session.key().ok_or(AppError::InputError("Нет ключа".into()))?;
    let vault = session.vault().ok_or(AppError::InputError("Нет хранилища".into()))?;
    let mode = session.mode().ok_or(AppError::InputError("Нет режима".into()))?;

    match mode {
        Mode::Real => vault_file::save_vault(vault, key)?,
        Mode::Duress => vault_file::save_decoy(vault, key)?,
    }
    Ok(())
}

/// Заблокирует сессию (затирает ключ из памяти).
pub fn lock_session(session: &mut Session) {
    session.lock();
}

// ===== ЧАСТЬ 2: CRUD =====

/// Добавляет новую запись в хранилище. Возвращает id.
pub fn add_entry(
    session: &mut Session,
    service: String,
    username: String,
    password: String,
    note: String,
) -> Result<u64> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    if vault.len() >= FREE_LIMIT {
        return Err(AppError::LimitExceeded(FREE_LIMIT));
    }

    let id = vault.add_entry(service, username, password, note);
    save_session(session)?;
    Ok(id)
}

/// Обновляет существующую запись.
pub fn update_entry(
    session: &mut Session,
    id: u64,
    service: String,
    username: String,
    password: String,
    note: String,
) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    vault.update_entry(id, service, username, password, note)?;
    save_session(session)?;
    Ok(())
}

/// Удаляет запись по id.
pub fn delete_entry(session: &mut Session, id: u64) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    vault.delete_entry(id)?;
    save_session(session)?;
    Ok(())
}

/// Возвращает копию записи по id.
pub fn get_entry(session: &Session, id: u64) -> Result<PasswordEntry> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    vault
        .find_by_id(id)
        .cloned()
        .ok_or(AppError::EntryNotFound(id))
}

/// Ищет записи по подстроке. Возвращает копии.
pub fn search_entries(session: &Session, query: &str) -> Result<Vec<PasswordEntry>> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    Ok(vault.search(query).into_iter().cloned().collect())
}

/// Меняет мастер-пароль: проверяет старый, генерирует новый ключ,
/// перешифровывает хранилище и обновляет конфиг.
pub fn change_master_password(
    session: &mut Session,
    old_password: &str,
    new_password: &str,
) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    if session.mode() != Some(Mode::Real) {
        return Err(AppError::InputError(
            "Смена пароля недоступна в duress-режиме".into(),
        ));
    }

    // 1. Загружаем конфиг и декодируем старую соль
    let config = vault_file::load_config()?;
    let old_salt = STANDARD
        .decode(&config.salt)
        .map_err(|e| AppError::Crypto(format!("Base64 error: {}", e)))?;

    // 2. Проверяем старый пароль — пытаемся расшифровать хранилище
    let old_key = kdf::derive_key(old_password, &old_salt)?;
    vault_file::load_vault(&old_key).map_err(|_| AppError::InvalidPassword)?;

    // 3. Генерируем новую соль и новый ключ
    let new_salt = kdf::generate_salt();
    let new_salt_b64 = STANDARD.encode(new_salt);
    let new_key = kdf::derive_key(new_password, &new_salt)?;

    // 4. Клонируем текущее хранилище
    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?
        .clone();

    // 5. Сохраняем хранилище с новым ключом
    vault_file::save_vault(&vault, &new_key)?;

    // 6. Обновляем соль в конфиге и сохраняем его
    session.config_mut().salt = new_salt_b64;
    vault_file::save_config(session.config())?;

    // 7. Переразблокируем сессию с новым ключом (старый key затирается через zeroize)
   session.unlock(new_key, vault, Mode::Real);

    Ok(())
}

/// Экспортирует все записи в JSON-файл.
pub fn export_to_json(session: &Session, path: &str) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;
    let json = serde_json::to_string_pretty(vault)?;
    std::fs::write(path, json)?;
    Ok(())
}

/// Умный импорт: определяет формат (JSON/CSV) и структуру автоматически.
pub fn import_from_file(session: &mut Session, path: &str) -> Result<usize> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }

    let p = std::path::Path::new(path);
    if p.is_dir() {
        return Err(AppError::InputError(
            "Указан путь к папке, а не к файлу".into(),
        ));
    }
    if !p.exists() {
        return Err(AppError::InputError("Файл не найден".into()));
    }

    let content = std::fs::read_to_string(path)?;
    let trimmed = content.trim_start();

    let parsed: Vec<(String, String, String, String)> =
        if trimmed.starts_with('{') || trimmed.starts_with('[') {
            parse_json_smart(&content)?
        } else {
            parse_csv_smart(&content)?
        };

    if parsed.is_empty() {
        return Err(AppError::InputError(
            "Не найдено ни одной записи для импорта".into(),
        ));
    }

    let vault = session
        .vault_mut()
        .ok_or_else(|| AppError::InputError("Нет хранилища".into()))?;

    let mut count = 0;
    for (service, username, password, note) in parsed {
        vault.add_entry(service, username, password, note);
        count += 1;
    }

    save_session(session)?;
    Ok(count)
}

/// Достаёт строку из JSON по списку возможных ключей.
fn json_get_str(value: &serde_json::Value, keys: &[&str]) -> Option<String> {
    for key in keys {
        if let Some(v) = value.get(*key) {
            if let Some(s) = v.as_str() {
                if !s.trim().is_empty() {
                    return Some(s.to_string());
                }
            }
            if let Some(n) = v.as_i64() {
                return Some(n.to_string());
            }
        }
    }
    None
}

/// Парсит JSON любого формата: массив, {entries:[...]}, {items:[...]}.
fn parse_json_smart(content: &str) -> Result<Vec<(String, String, String, String)>> {
    let value: serde_json::Value = serde_json::from_str(content)
        .map_err(|e| AppError::InputError(format!("Ошибка JSON: {}", e)))?;

    let arr = if value.is_array() {
        value.as_array().cloned().unwrap_or_default()
    } else if let Some(a) = value.get("entries").and_then(|v| v.as_array()) {
        a.clone()
    } else if let Some(a) = value.get("items").and_then(|v| v.as_array()) {
        a.clone()
    } else if let Some(a) = value.get("passwords").and_then(|v| v.as_array()) {
        a.clone()
    } else if let Some(a) = value.get("logins").and_then(|v| v.as_array()) {
        a.clone()
    } else {
        return Err(AppError::InputError(
            "Не удалось распознать структуру JSON. Ожидался массив или объект с 'entries'/'items'."
                .into(),
        ));
    };

    let mut result = Vec::new();
    for item in arr.iter() {
        let service = json_get_str(
            item,
            &["service", "name", "url", "title", "site", "host", "domain"],
        )
        .unwrap_or_default();
        let username = json_get_str(
            item,
            &["username", "login", "email", "user", "account"],
        )
        .unwrap_or_default();
        let password = json_get_str(item, &["password", "pass", "pwd", "secret"])
            .unwrap_or_default();
        let note = json_get_str(
            item,
            &["note", "notes", "comment", "description", "extra"],
        )
        .unwrap_or_default();

        if service.is_empty() && username.is_empty() && password.is_empty() {
            continue;
        }

        result.push((
            if service.is_empty() { "unknown".to_string() } else { service },
            username,
            password,
            note,
        ));
    }

    Ok(result)
}

/// Парсит CSV любого формата с автоопределением колонок.
fn parse_csv_smart(content: &str) -> Result<Vec<(String, String, String, String)>> {
    let mut rdr = csv::ReaderBuilder::new()
        .flexible(true)
        .from_reader(content.as_bytes());

    let headers = rdr
        .headers()
        .map_err(|e| AppError::InputError(format!("Ошибка CSV: {}", e)))?
        .clone();

    let headers_lower: Vec<String> = headers
        .iter()
        .map(|h| h.trim().trim_matches('"').to_lowercase())
        .collect();

    let find = |candidates: &[&str]| -> Option<usize> {
        for (i, h) in headers_lower.iter().enumerate() {
            for c in candidates {
                if h == c || h.contains(c) {
                    return Some(i);
                }
            }
        }
        None
    };

    let i_service = find(&["name", "service", "url", "title", "site", "host", "domain"]);
    let i_user = find(&["username", "login", "email", "user", "account"]);
    let i_pass = find(&["password", "pass", "pwd", "secret"]);
    let i_note = find(&["note", "notes", "comment", "description", "extra"]);

    let mut result = Vec::new();
    for rec in rdr.records() {
        let rec = rec.map_err(|e| AppError::InputError(format!("Ошибка CSV: {}", e)))?;
        let get = |idx: Option<usize>| -> String {
            idx.and_then(|i| rec.get(i))
                .unwrap_or("")
                .trim()
                .trim_matches('"')
                .to_string()
        };

        let service = get(i_service);
        let username = get(i_user);
        let password = get(i_pass);
        let note = get(i_note);

        if service.is_empty() && username.is_empty() && password.is_empty() {
            continue;
        }

        result.push((
            if service.is_empty() { "unknown".to_string() } else { service },
            username,
            password,
            note,
        ));
    }

    Ok(result)
}

/// Экспортирует записи в CSV-файл.
pub fn export_to_csv(session: &Session, path: &str) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    let mut csv = String::from("id,service,username,password,note,created_at,updated_at\n");
    for entry in &vault.entries {
        csv.push_str(&format!(
            "{},\"{}\",\"{}\",\"{}\",\"{}\",{},{}\n",
            entry.id,
            entry.service.replace('"', "\"\""),
            entry.username.replace('"', "\"\""),
            entry.password.replace('"', "\"\""),
            entry.note.replace('"', "\"\""),
            entry.created_at,
            entry.updated_at
        ));
    }
    std::fs::write(path, csv)?;
    Ok(())
}
/// Создаёт новую папку. Возвращает id.
pub fn add_folder(session: &mut Session, name: String) -> Result<u64> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;
    let id = vault.add_folder(name);
    save_session(session)?;
    Ok(id)
}

/// Удаляет папку по id.
pub fn delete_folder(session: &mut Session, id: u64) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;
    vault.delete_folder(id)?;
    save_session(session)?;
    Ok(())
}

/// Возвращает список папок.
pub fn list_folders(session: &Session) -> Result<Vec<(u64, String)>> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;
    Ok(vault.folders.iter().map(|f| (f.id, f.name.clone())).collect())
}

/// Перемещает запись в папку (folder_id = Some(id)) или вынимает (None).
pub fn move_entry_to_folder(
    session: &mut Session,
    entry_id: u64,
    folder_id: Option<u64>,
) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault_mut()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;

    if let Some(fid) = folder_id {
        if vault.find_folder(fid).is_none() {
            return Err(AppError::InputError("Папка не найдена".into()));
        }
    }

    let entry = vault
        .find_by_id_mut(entry_id)
        .ok_or(AppError::EntryNotFound(entry_id))?;
    entry.folder_id = folder_id;
    entry.touch();

    save_session(session)?;
    Ok(())
}

/// Записи в конкретной папке. None — записи без папки.
pub fn list_entries_in_folder(
    session: &Session,
    folder_id: Option<u64>,
) -> Result<Vec<PasswordEntry>> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    let vault = session
        .vault()
        .ok_or(AppError::InputError("Нет хранилища".into()))?;
    Ok(vault
        .entries
        .iter()
        .filter(|e| e.folder_id == folder_id)
        .cloned()
        .collect())
}
/// Устанавливает duress-пароль (ложное хранилище).
/// Создаёт пустое ложное хранилище с новым ключом.
pub fn set_duress_password(session: &mut Session, duress_password: &str) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    if session.mode() != Some(Mode::Real) {
        return Err(AppError::InputError(
            "Установить duress-пароль можно только из настоящего хранилища".into(),
        ));
    }

    let salt = kdf::generate_salt();
    let salt_b64 = STANDARD.encode(salt);
    let key = kdf::derive_key(duress_password, &salt)?;

    let decoy_vault = Vault::new();
    vault_file::save_decoy(&decoy_vault, &key)?;

    session.config_mut().set_decoy_salt(salt_b64);
    vault_file::save_config(session.config())?;

    Ok(())
}

/// Удаляет duress-пароль (и файл decoy.enc).
pub fn remove_duress_password(session: &mut Session) -> Result<()> {
    if !session.is_unlocked() {
        return Err(AppError::InputError("Сессия заблокирована".into()));
    }
    if session.mode() != Some(Mode::Real) {
        return Err(AppError::InputError(
            "Удалить duress-пароль можно только из настоящего хранилища".into(),
        ));
    }

    let path = paths::decoy_path();
    if path.exists() {
        std::fs::remove_file(path)?;
    }

    session.config_mut().clear_decoy_salt();
    vault_file::save_config(session.config())?;

    Ok(())
}