use serde::{Serialize, Deserialize};

/// Папка для группировки записей.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Folder {
    pub id: u64,
    pub name: String,
}

impl Folder {
    pub fn new(id: u64, name: String) -> Self {
        Self { id, name }
    }
}