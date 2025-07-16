-- Unit tests for folders configuration module

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local folders = require('neotex.plugins.tools.himalaya.config.folders')

local M = {}

-- Test module initialization
function M.test_init()
  local config = {
    accounts = {
      gmail = {
        maildir_path = '~/Mail/Gmail/',
        folder_map = {
          ['INBOX'] = 'INBOX',
          ['[Gmail]/Sent Mail'] = 'Sent'
        },
        local_to_imap = {
          ['INBOX'] = 'INBOX',
          ['Sent'] = '[Gmail]/Sent Mail'
        }
      }
    },
    sync = {
      maildir_root = '~/TestMail'
    }
  }
  
  folders.init(config)
  
  -- Test maildir root was set
  test_framework.assert.equals(
    folders.get_maildir_root(),
    '~/TestMail',
    'Should set maildir root'
  )
end

-- Test folder name mapping
function M.test_folder_name_mapping()
  local config = {
    accounts = {
      gmail = {
        folder_map = {
          ['[Gmail]/All Mail'] = 'All_Mail',
          ['[Gmail]/Drafts'] = 'Drafts'
        },
        local_to_imap = {
          ['All_Mail'] = '[Gmail]/All Mail',
          ['Drafts'] = '[Gmail]/Drafts'
        }
      }
    }
  }
  
  folders.init(config)
  
  -- Test IMAP to local
  test_framework.assert.equals(
    folders.get_local_folder_name('[Gmail]/All Mail', 'gmail'),
    'All_Mail',
    'Should map IMAP to local'
  )
  
  -- Test unmapped folder
  test_framework.assert.equals(
    folders.get_local_folder_name('Custom', 'gmail'),
    'Custom',
    'Should return unmapped folder as-is'
  )
  
  -- Test local to IMAP
  test_framework.assert.equals(
    folders.get_imap_folder_name('All_Mail', 'gmail'),
    '[Gmail]/All Mail',
    'Should map local to IMAP'
  )
end

-- Test maildir path construction
function M.test_get_maildir_path()
  local config = {
    accounts = {
      with_path = {
        maildir_path = '~/CustomMail/Account1/'
      },
      without_path = {}
    },
    sync = {
      maildir_root = '~/GlobalMail'
    }
  }
  
  folders.init(config)
  
  -- Test account with specific path
  local path = folders.get_maildir_path('with_path')
  -- Just check it ends with the expected path, regardless of home expansion
  test_framework.assert.truthy(
    path:match('CustomMail/Account1/?$'),
    'Should use account-specific path: ' .. path
  )
  
  -- Test account using global root
  path = folders.get_maildir_path('without_path')
  test_framework.assert.truthy(
    path:match('GlobalMail/without_path/?$'),
    'Should use global maildir root: ' .. path
  )
  
  -- Test fallback for unknown account
  path = folders.get_maildir_path('unknown')
  test_framework.assert.truthy(
    path:match('GlobalMail/unknown/$'),
    'Should construct path for unknown account'
  )
end

-- Test folder path construction
function M.test_get_folder_path()
  local config = {
    accounts = {
      test = {
        folder_map = {
          ['INBOX'] = 'INBOX',
          ['[Gmail]/Drafts'] = 'Drafts'
        }
      }
    },
    sync = {
      maildir_root = '~/Mail'
    }
  }
  
  folders.init(config)
  
  -- Test regular folder
  local path = folders.get_folder_path('test', '[Gmail]/Drafts')
  test_framework.assert.truthy(
    path:match('Mail/test/%.Drafts$'),
    'Should construct folder path with dot prefix'
  )
  
  -- Test INBOX (no dot prefix)
  path = folders.get_folder_path('test', 'INBOX')
  test_framework.assert.truthy(
    path:match('Mail/test/INBOX$'),
    'INBOX should not have dot prefix'
  )
end

-- Test special folders
function M.test_get_special_folders()
  local config = {
    accounts = {
      gmail = {
        folder_map = {
          ['[Gmail]/Drafts'] = 'MyDrafts',
          ['[Gmail]/Sent Mail'] = 'MySent',
          ['[Gmail]/Trash'] = 'MyTrash'
        }
      },
      standard = {}
    }
  }
  
  folders.init(config)
  
  -- Test mapped special folders
  local special = folders.get_special_folders('gmail')
  test_framework.assert.equals(special.drafts, 'MyDrafts', 'Should map drafts')
  test_framework.assert.equals(special.sent, 'MySent', 'Should map sent')
  test_framework.assert.equals(special.trash, 'MyTrash', 'Should map trash')
  
  -- Test default special folders
  special = folders.get_special_folders('standard')
  test_framework.assert.equals(special.drafts, 'Drafts', 'Should use default drafts')
  test_framework.assert.equals(special.sent, 'Sent', 'Should use default sent')
  test_framework.assert.equals(special.trash, 'Trash', 'Should use default trash')
end

-- Test update folder mapping
function M.test_update_folder_mapping()
  local config = {
    accounts = {
      test = {
        folder_map = {
          ['Old'] = 'old_local'
        },
        local_to_imap = {
          ['old_local'] = 'Old'
        }
      }
    }
  }
  
  folders.init(config)
  
  -- Add new mapping
  folders.update_folder_mapping('test', 'New Folder', 'new_local')
  
  test_framework.assert.equals(
    folders.get_local_folder_name('New Folder', 'test'),
    'new_local',
    'Should add new IMAP to local mapping'
  )
  
  test_framework.assert.equals(
    folders.get_imap_folder_name('new_local', 'test'),
    'New Folder',
    'Should add new local to IMAP mapping'
  )
  
  -- Verify old mapping still exists
  test_framework.assert.equals(
    folders.get_local_folder_name('Old', 'test'),
    'old_local',
    'Should preserve existing mappings'
  )
end

-- Test has_folder
function M.test_has_folder()
  local config = {
    accounts = {
      test = {
        folder_map = {
          ['IMAP Name'] = 'local_name'
        },
        local_to_imap = {
          ['local_name'] = 'IMAP Name'
        }
      }
    }
  }
  
  folders.init(config)
  
  -- Test IMAP name
  test_framework.assert.truthy(
    folders.has_folder('test', 'IMAP Name'),
    'Should find folder by IMAP name'
  )
  
  -- Test local name
  test_framework.assert.truthy(
    folders.has_folder('test', 'local_name'),
    'Should find folder by local name'
  )
  
  -- Test non-existent folder
  test_framework.assert.falsy(
    folders.has_folder('test', 'nonexistent'),
    'Should not find non-existent folder'
  )
  
  -- Test non-existent account
  test_framework.assert.falsy(
    folders.has_folder('unknown', 'any'),
    'Should not find folder in non-existent account'
  )
end

return M