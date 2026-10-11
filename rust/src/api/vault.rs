use std::sync::{Mutex, OnceLock};

use crate::core::session::{Mode, Session};
use crate::core::manager;
use crate::models::entry::PasswordEntry;

static SESSION: OnceLock<Mutex<Option<Session>>> = OnceLock::new();

fn session_mutex() -> &'static Mutex<Option<Session>> {
    SESSION.get_or_init(|| Mutex::new(None))
}

fn with_session_mut<F, T>(f: F) -> Result<T, String>
where
    F: FnOnce(&mut Session) -> Result<T, String>,
{
    let mutex = session_mutex();
    let mut guard = mutex.lock().map_err(|e| format!("Lock error: {}", e))?;
    let session = guard
        .as_mut()
        .ok_or_else(|| "Сессия не открыта".to_string())?;
    f(session)
}

/// Создать новое хранилище.
#[flutter_rust_bridge::frb]
pub fn create_vault(password: String) -> Result<(), String> {
    let session = manager::create_vault(&password).map_err(|e| e.to_string())?;
    let mutex = session_mutex();
    let mut guard = mutex.lock().map_err(|e| format!("Lock error: {}", e))?;
    *guard = Some(session);
    Ok(())
}

/// Разблокировать хранилище. Возвращает true, если duress-режим.
#[flutter_rust_bridge::frb]
pub fn unlock_vault(password: String) -> Result<bool, String> {
    let session = manager::unlock_vault(&password).map_err(|e| e.to_string())?;
    let is_duress = session.mode() == Some(Mode::Duress);
    let mutex = session_mutex();
    let mut guard = mutex.lock().map_err(|e| format!("Lock error: {}", e))?;
    *guard = Some(session);
    Ok(is_duress)
}

/// Проверить, существует ли хранилище на диске.
#[flutter_rust_bridge::frb]
pub fn vault_exists() -> bool {
    crate::storage::vault_file::vault_exists()
}

/// Открыта ли сессия сейчас.
#[flutter_rust_bridge::frb]
pub fn is_unlocked() -> bool {
    let mutex = session_mutex();
    if let Ok(guard) = mutex.lock() {
        if let Some(s) = guard.as_ref() {
            return s.is_unlocked();
        }
    }
    false
}

/// Заблокировать сессию.
#[flutter_rust_bridge::frb]
pub fn lock_session() {
    let mutex = session_mutex();
    if let Ok(mut guard) = mutex.lock() {
        if let Some(s) = guard.as_mut() {
            manager::lock_session(s);
        }
        *guard = None;
    }
}

/// DTO для передачи записи в Dart.
pub struct EntryDto {
    pub id: u64,
    pub service: String,
    pub username: String,
    pub password: String,
    pub note: String,
    pub folder_id: Option<u64>,
    pub created_at: u64,
    pub updated_at: u64,
}

impl From<PasswordEntry> for EntryDto {
    fn from(e: PasswordEntry) -> Self {
        Self {
            id: e.id,
            service: e.service,
            username: e.username,
            password: e.password,
            note: e.note,
            folder_id: e.folder_id,
            created_at: e.created_at,
            updated_at: e.updated_at,
        }
    }
}

/// Получить все записи.
#[flutter_rust_bridge::frb]
pub fn list_entries() -> Result<Vec<EntryDto>, String> {
    with_session_mut(|session| {
        let vault = session.vault().ok_or_else(|| "Нет хранилища".to_string())?;
        Ok(vault
            .entries
            .iter()
            .map(|e| EntryDto::from(e.clone()))
            .collect())
    })
}

/// Добавить запись. Возвращает id.
#[flutter_rust_bridge::frb]
pub fn add_entry(
    service: String,
    username: String,
    password: String,
    note: String,
) -> Result<u64, String> {
    with_session_mut(|session| {
        manager::add_entry(session, service, username, password, note)
            .map_err(|e| e.to_string())
    })
}

/// Получить одну запись по id.
#[flutter_rust_bridge::frb]
pub fn get_entry(id: u64) -> Result<EntryDto, String> {
    with_session_mut(|session| {
        manager::get_entry(session, id)
            .map(EntryDto::from)
            .map_err(|e| e.to_string())
    })
}

/// Удалить запись по id.
#[flutter_rust_bridge::frb]
pub fn delete_entry(id: u64) -> Result<(), String> {
    with_session_mut(|session| {
        manager::delete_entry(session, id).map_err(|e| e.to_string())
    })
}

/// Найти записи по подстроке.
#[flutter_rust_bridge::frb]
pub fn search_entries(query: String) -> Result<Vec<EntryDto>, String> {
    with_session_mut(|session| {
        manager::search_entries(session, &query)
            .map(|v| v.into_iter().map(EntryDto::from).collect())
            .map_err(|e| e.to_string())
    })
}
/// Обновить запись по id.
#[flutter_rust_bridge::frb]
pub fn update_entry(
    id: u64,
    service: String,
    username: String,
    password: String,
    note: String,
) -> Result<(), String> {
    with_session_mut(|session| {
        manager::update_entry(session, id, service, username, password, note)
            .map_err(|e| e.to_string())
    })
}
/// Сгенерировать случайный пароль.
#[flutter_rust_bridge::frb]
pub fn generate_password(length: u32, use_symbols: bool) -> Result<String, String> {
    crate::generator::generate(length as usize, use_symbols).map_err(|e| e.to_string())
}
/// DTO для папки.
pub struct FolderDto {
    pub id: u64,
    pub name: String,
}

/// Список всех папок.
#[flutter_rust_bridge::frb]
pub fn list_folders() -> Result<Vec<FolderDto>, String> {
    with_session_mut(|session| {
        manager::list_folders(session)
            .map(|v| {
                v.into_iter()
                    .map(|(id, name)| FolderDto { id, name })
                    .collect()
            })
            .map_err(|e| e.to_string())
    })
}

/// Создать папку. Возвращает id.
#[flutter_rust_bridge::frb]
pub fn add_folder(name: String) -> Result<u64, String> {
    with_session_mut(|session| {
        manager::add_folder(session, name).map_err(|e| e.to_string())
    })
}

/// Удалить папку по id.
#[flutter_rust_bridge::frb]
pub fn delete_folder(id: u64) -> Result<(), String> {
    with_session_mut(|session| {
        manager::delete_folder(session, id).map_err(|e| e.to_string())
    })
}

/// Переместить запись в папку (None — вынуть из папки).
#[flutter_rust_bridge::frb]
pub fn move_entry_to_folder(
    entry_id: u64,
    folder_id: Option<u64>,
) -> Result<(), String> {
    with_session_mut(|session| {
        manager::move_entry_to_folder(session, entry_id, folder_id)
            .map_err(|e| e.to_string())
    })
}

/// Записи в папке (None — без папки).
#[flutter_rust_bridge::frb]
pub fn list_entries_in_folder(folder_id: Option<u64>) -> Result<Vec<EntryDto>, String> {
    with_session_mut(|session| {
        manager::list_entries_in_folder(session, folder_id)
            .map(|v| v.into_iter().map(EntryDto::from).collect())
            .map_err(|e| e.to_string())
    })
}
/// Сменить мастер-пароль.
#[flutter_rust_bridge::frb]
pub fn change_master_password(
    old_password: String,
    new_password: String,
) -> Result<(), String> {
    with_session_mut(|session| {
        manager::change_master_password(session, &old_password, &new_password)
            .map_err(|e| e.to_string())
    })
}

/// Установить duress-пароль.
#[flutter_rust_bridge::frb]
pub fn set_duress_password(password: String) -> Result<(), String> {
    with_session_mut(|session| {
        manager::set_duress_password(session, &password)
            .map_err(|e| e.to_string())
    })
}

/// Удалить duress-пароль.
#[flutter_rust_bridge::frb]
pub fn remove_duress_password() -> Result<(), String> {
    with_session_mut(|session| {
        manager::remove_duress_password(session).map_err(|e| e.to_string())
    })
}

/// Есть ли уже duress-пароль.
#[flutter_rust_bridge::frb]
pub fn has_duress_password() -> bool {
    let mutex = session_mutex();
    if let Ok(guard) = mutex.lock() {
        if let Some(s) = guard.as_ref() {
            return s.config().decoy_salt.is_some();
        }
    }
    false
}

/// Экспорт в JSON.
#[flutter_rust_bridge::frb]
pub fn export_to_json(path: String) -> Result<(), String> {
    with_session_mut(|session| {
        manager::export_to_json(session, &path).map_err(|e| e.to_string())
    })
}

/// Умный импорт из JSON или CSV.
#[flutter_rust_bridge::frb]
pub fn import_from_file(path: String) -> Result<u32, String> {
    with_session_mut(|session| {
        manager::import_from_file(session, &path)
            .map(|n| n as u32)
            .map_err(|e| e.to_string())
    })
}


/// Экспорт в CSV.
#[flutter_rust_bridge::frb]
pub fn export_to_csv(path: String) -> Result<(), String> {
    with_session_mut(|session| {
        manager::export_to_csv(session, &path).map_err(|e| e.to_string())
    })
}