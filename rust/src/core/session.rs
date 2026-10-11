use std::time::Instant;
use zeroize::Zeroize;
use crate::models::{Vault, Config};

/// Режим работы сессии.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    /// Настоящее хранилище.
    Real,
    /// Ложное (duress) хранилище.
    Duress,
}

/// Состояние сессии.
enum SessionState {
    Locked,
    Unlocked {
        key: [u8; 32],
        vault: Vault,
        mode: Mode,
    },
}

/// Управляет состоянием приложения.
pub struct Session {
    state: SessionState,
    config: Config,
    last_activity: Instant,
}

impl Session {
    pub fn new_locked(config: Config) -> Self {
        Self {
            state: SessionState::Locked,
            config,
            last_activity: Instant::now(),
        }
    }

    pub fn unlock(&mut self, key: [u8; 32], vault: Vault, mode: Mode) {
        if let SessionState::Unlocked { key: old_key, .. } = &mut self.state {
            old_key.zeroize();
        }
        self.state = SessionState::Unlocked { key, vault, mode };
    }

    pub fn lock(&mut self) {
        if let SessionState::Unlocked { key, .. } = &mut self.state {
            key.zeroize();
        }
        self.state = SessionState::Locked;
    }

    pub fn is_unlocked(&self) -> bool {
        matches!(self.state, SessionState::Unlocked { .. })
    }

    pub fn key(&self) -> Option<&[u8; 32]> {
        if let SessionState::Unlocked { ref key, .. } = self.state {
            Some(key)
        } else {
            None
        }
    }

    pub fn mode(&self) -> Option<Mode> {
        if let SessionState::Unlocked { mode, .. } = self.state {
            Some(mode)
        } else {
            None
        }
    }

    pub fn vault(&self) -> Option<&Vault> {
        if let SessionState::Unlocked { ref vault, .. } = self.state {
            Some(vault)
        } else {
            None
        }
    }

    pub fn vault_mut(&mut self) -> Option<&mut Vault> {
        if let SessionState::Unlocked { ref mut vault, .. } = self.state {
            Some(vault)
        } else {
            None
        }
    }

    pub fn config(&self) -> &Config {
        &self.config
    }

    pub fn config_mut(&mut self) -> &mut Config {
        &mut self.config
    }

    /// Обновляет время последней активности.
    pub fn touch(&mut self) {
        self.last_activity = Instant::now();
    }

    /// Сколько минут прошло с последней активности.
    pub fn idle_minutes(&self) -> u64 {
        self.last_activity.elapsed().as_secs() / 60
    }

    /// Пора ли автоблокировать сессию.
    pub fn should_autolock(&self) -> bool {
        let limit = self.config.autolock_minutes as u64;
        limit > 0 && self.idle_minutes() >= limit
    }
}