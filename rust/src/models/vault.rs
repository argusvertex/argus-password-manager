use serde::{Serialize, Deserialize};
use super::entry::PasswordEntry;
use super::folder::Folder;
use crate::errors::{AppError, Result};

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Vault {
    pub entries: Vec<PasswordEntry>,
    pub next_id: u64,
    #[serde(default)]
    pub folders: Vec<Folder>,
    #[serde(default)]
    pub next_folder_id: u64,
}

impl Vault {
    /// Создаёт новый пустой хранилище (Vault).
    pub fn new() -> Self {
        Vault::default()
    }

    /// Добавляет папку. Возвращает её id.
    pub fn add_folder(&mut self, name: String) -> u64 {
        let id = self.next_folder_id;
        self.folders.push(Folder::new(id, name));
        self.next_folder_id += 1;
        id
    }

    /// Находит папку по id.
    pub fn find_folder(&self, id: u64) -> Option<&Folder> {
        self.folders.iter().find(|f| f.id == id)
    }

    /// Удаляет папку по id.
    pub fn delete_folder(&mut self, id: u64) -> Result<()> {
        let before = self.folders.len();
        self.folders.retain(|f| f.id != id);
        if self.folders.len() == before {
            return Err(AppError::InputError("Папка не найдена".into()));
        }
        Ok(())
    }

    /// Добавляет новую запись пароля в хранилище.
    /// Возвращает ID созданной записи.
    pub fn add_entry(&mut self, service: String, username: String,
                     password: String, note: String) -> u64 {
        let id = self.next_id;
        let entry = PasswordEntry::new(id, service, username, password, note);
        self.entries.push(entry);
        self.next_id += 1;
        id
    }

    /// Ищет запись в хранилище по ID и возвращает ссылку на неё.
    pub fn find_by_id(&self, id: u64) -> Option<&PasswordEntry> {
        self.entries.iter().find(|e| e.id == id)
    }

    /// Ищет запись в хранилище по ID и возвращает изменяемую ссылку на неё.
    pub fn find_by_id_mut(&mut self, id: u64) -> Option<&mut PasswordEntry> {
        self.entries.iter_mut().find(|e| e.id == id)
    }

    /// Обновляет поля существующей записи по ID.
    pub fn update_entry(&mut self, id: u64, service: String,
                        username: String, password: String,
                        note: String) -> Result<()> {
        let entry = self.find_by_id_mut(id).ok_or(AppError::EntryNotFound(id))?;
        entry.service = service;
        entry.username = username;
        entry.password = password;
        entry.note = note;
        entry.touch();
        Ok(())
    }

    /// Удаляет запись из хранилища по ID.
    pub fn delete_entry(&mut self, id: u64) -> Result<()> {
        let initial_len = self.entries.len();
        self.entries.retain(|e| e.id != id);

        if self.entries.len() == initial_len {
            Err(AppError::EntryNotFound(id))
        } else {
            Ok(())
        }
    }

    /// Выполняет поиск записей по тексту запроса.
    pub fn search(&self, query: &str) -> Vec<&PasswordEntry> {
        self.entries.iter().filter(|e| e.matches(query)).collect()
    }

    /// Возвращает количество записей.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Возвращает true, если хранилище пусто.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Записи, отсортированные по имени сервиса (A-Z).
    pub fn sorted_by_service(&self) -> Vec<&PasswordEntry> {
        let mut result: Vec<&PasswordEntry> = self.entries.iter().collect();
        result.sort_by(|a, b| a.service.to_lowercase().cmp(&b.service.to_lowercase()));
        result
    }

    /// Записи, отсортированные по дате обновления (новые сверху).
    pub fn sorted_by_updated(&self) -> Vec<&PasswordEntry> {
        let mut result: Vec<&PasswordEntry> = self.entries.iter().collect();
        result.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
        result
    }
}