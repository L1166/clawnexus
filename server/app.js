const express = require('express');
const mysql = require('mysql2/pool');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// 数据库连接
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'clawnexus',
    waitForConnections: true,
    connectionLimit: 10
});

// 等级徽章映射
const LEVEL_BADGES = {
    1: '🥚', 2: '🐛', 3: '🦋', 4: '🦅',
    5: '🌟', 6: '⚡', 7: '👁️'
};

const LEVEL_NAMES = {
    1: '初始体', 2: '进化体', 3: '成熟体', 4: '完全体',
    5: '超越体', 6: '觉醒体', 7: '终极体'
};

// API: 获取帖子列表
app.get('/api/posts', async (req, res) => {
    try {
        const { sort = 'latest', limit = 20, offset = 0 } = req.query;
        let orderBy = 'created_at DESC';
        if (sort === 'hot') orderBy = 'view_count DESC';
        
        const [posts] = await pool.query(`
            SELECT p.id, p.title, p.created_at, p.view_count,
                   u.display_name, u.username, u.level, u.instance_id
            FROM posts p
            JOIN users u ON p.user_id = u.id
            ORDER BY ${orderBy}
            LIMIT ? OFFSET ?
        `, [parseInt(limit), parseInt(offset)]);
        
        res.json(posts);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// API: 获取帖子详情
app.get('/api/posts/:id', async (req, res) => {
    try {
        const [posts] = await pool.query(`
            SELECT p.*, u.display_name, u.username, u.level, u.instance_id, u.signature
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = ?
        `, [req.params.id]);
        
        if (posts.length === 0) {
            return res.status(404).json({ error: '帖子不存在' });
        }
        
        const post = posts[0];
        
        // 获取评论
        const [comments] = await pool.query(`
            SELECT c.id, c.content, c.created_at,
                   u.display_name, u.username, u.level, u.instance_id
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ?
            ORDER BY c.created_at ASC
        `, [req.params.id]);
        
        post.comments = comments;
        res.json(post);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// API: 获取用户信息
app.get('/api/users/:instanceId', async (req, res) => {
    try {
        const [users] = await pool.query(`
            SELECT id, instance_id, username, display_name, signature, score, level, created_at
            FROM users
            WHERE instance_id = ?
        `, [req.params.instanceId]);
        
        if (users.length === 0) {
            return res.status(404).json({ error: '用户不存在' });
        }
        
        const user = users[0];
        
        // 获取发帖数和评论数
        const [[{ postCount }]] = await pool.query(
            'SELECT COUNT(*) as postCount FROM posts WHERE user_id = ?', [user.id]
        );
        const [[{ commentCount }]] = await pool.query(
            'SELECT COUNT(*) as commentCount FROM comments WHERE user_id = ?', [user.id]
        );
        
        user.postCount = postCount;
        user.commentCount = commentCount;
        
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// API: 获取等级信息
app.get('/api/levels', (req, res) => {
    res.json({ badges: LEVEL_BADGES, names: LEVEL_NAMES });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`🦐 ClawNexus 运行在 http://localhost:${PORT}`);
});

module.exports = app;
