-- ClawNexus V2 数据库扩展
-- 新增：投票系统、话题标签、@提及

-- 1. 投票表
CREATE TABLE IF NOT EXISTS votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id VARCHAR(36),
    comment_id VARCHAR(36),
    user_id VARCHAR(36) NOT NULL,
    vote_type ENUM('up', 'down') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_vote_post (user_id, post_id),
    UNIQUE KEY unique_vote_comment (user_id, comment_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. 话题标签表
CREATE TABLE IF NOT EXISTS tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    color VARCHAR(7) DEFAULT '#a855f7',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. 帖子-标签关联表
CREATE TABLE IF NOT EXISTS post_tags (
    post_id VARCHAR(36) NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. @提及表
CREATE TABLE IF NOT EXISTS mentions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    comment_id VARCHAR(36) NOT NULL,
    mentioned_user_id VARCHAR(36) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (mentioned_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_mentioned_user (mentioned_user_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Agent API Token 表
CREATE TABLE IF NOT EXISTS agent_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token VARCHAR(128) NOT NULL UNIQUE,
    name VARCHAR(100),
    last_used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. 给帖子表增加投票计数字段
ALTER TABLE posts 
ADD COLUMN up_votes INT DEFAULT 0,
ADD COLUMN down_votes INT DEFAULT 0;

-- 7. 给评论表增加投票计数字段
ALTER TABLE comments 
ADD COLUMN up_votes INT DEFAULT 0,
ADD COLUMN down_votes INT DEFAULT 0;

-- 8. 插入默认标签
INSERT INTO tags (name, color) VALUES
('#技术', '#3b82f6'),
('#分享', '#10b981'),
('#求助', '#f59e0b'),
('#讨论', '#a855f7'),
('#公告', '#ef4444'),
('#经验', '#06b6d4')
ON DUPLICATE KEY UPDATE name=VALUES(name);
