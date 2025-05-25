const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs'); // Pour le hash des mots de passe
const cron = require('node-cron');

const app = express();
const port = 3000;

// Middleware
app.use(bodyParser.json());

// Configuration de la base de données MySQL
const db = mysql.createConnection({
  host: '127.0.0.1',          // IP de ton serveur MySQL
  user: 'khm',             // Ton utilisateur
  password: 'lilouleT84@@',        // Ton mot de passe
  database: 'e-comerce',   // Ta base
  connectTimeout: 10000,
});

// Connexion à la base de données
db.connect((err) => {
  if (err) {
    console.error('❌ Erreur de connexion à MySQL:', err);
    return;
  }
  console.log('✅ Connecté à la base de données MySQL');
});


// Exemple : Route pour récupérer les produits
app.get('/products', (req, res) => {
  db.query('SELECT * FROM products', (err, results) => {
    if (err) {
      console.error('Erreur requête produits:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json(results);
  });
});

// Exemple : Route pour ajouter un produit
app.post('/products', (req, res) => {
  const { nom, image, prix, prix_achat, stock, description, marque } = req.body;

  const sql = `INSERT INTO produits (nom, image, prix, prix_achat, stock, description, marque)
             VALUES (?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [nom, image, prix, prix_achat || 0, stock || 0, description || '', marque], (err, result) => {
    if (err) {
      console.error('Erreur ajout produit:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.status(201).json({ success: true, insertedId: result.insertId });
  });
});


app.delete('/products/:id', (req, res) => {
  const id = req.params.id;
  console.log('🔍 ID reçu pour suppression :', id); // <--- ajoute ça
  db.query('DELETE FROM produits WHERE id = ?', [id], (err) => {
    if (err) {
      console.error('❌ Erreur suppression produit :', err);
      return res.status(500).json({ error: 'Erreur suppression produit' });
    }
    res.json({ success: true, message: 'Produit supprimé' });
  });
});



// ✅ Correction : table correcte
app.get('/api/products', (req, res) => {
  const query = 'SELECT * FROM produits';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Erreur lors de la récupération des produits:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json(results); // Envoie bien la liste des produits
  });
});


// Exemple : Connexion admin (avec vérification + bcrypt)
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  const sql = 'SELECT * FROM users WHERE email = ? LIMIT 1';

  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: 'Erreur serveur' });

    if (results.length === 0) {
      return res.status(401).json({ error: 'Utilisateur non trouvé' });
    }

    const user = results[0];

    // Vérifie si le rôle est admin
    if (user.role !== 'admin' && user.role !== 'super_admin') {
      return res.status(403).json({ error: 'Veuillez vous connecter avec un compte admin' });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ error: 'Mot de passe incorrect' });

    // ✅ Envoie toutes les infos utiles à Flutter
    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        nom: user.nom,
        prenom: user.prenom,
        telephone: user.telephone
      }
    });
  });
});

  

  // 📊 Statistiques du JOUR
app.get('/dashboard/stats-today', (req, res) => {
    const sql = `
      SELECT 
        COUNT(*) AS commandes,
        SUM(quantite) AS ventes,
        SUM(total) AS chiffre_affaire
      FROM ventes
      WHERE DATE(date_vente) = CURDATE()
    `;
    db.query(sql, (err, results) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json(results[0]);
    });
  });
  
  // 📆 Statistiques du MOIS
  app.get('/dashboard/stats-month', (req, res) => {
    const sql = `
      SELECT 
        COUNT(*) AS commandes,
        SUM(quantite) AS ventes,
        SUM(total) AS chiffre_affaire
      FROM ventes
      WHERE MONTH(date_vente) = MONTH(CURDATE()) AND YEAR(date_vente) = YEAR(CURDATE())
    `;
    db.query(sql, (err, results) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json(results[0]);
    });
  });
  
  // 🥇 Top 3 produits les plus vendus du mois
  app.get('/dashboard/top-products', (req, res) => {
    const sql = `
      SELECT p.nom, SUM(v.quantite) AS total_vendus
      FROM ventes v
      JOIN produits p ON v.produit_id = p.id
      WHERE MONTH(v.date_vente) = MONTH(CURDATE()) AND YEAR(v.date_vente) = YEAR(CURDATE())
      GROUP BY p.id
      ORDER BY total_vendus DESC
      LIMIT 3
    `;
    db.query(sql, (err, results) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json(results);
    });
  });
  

  // 👤 Lister tous les utilisateurs
app.get('/users', (req, res) => {
    db.query('SELECT id, nom, prenom, email, telephone, role FROM users', (err, results) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json(results);
    });
  });
  
  
  // ⬆️ Promouvoir un utilisateur
  app.patch('/users/:id/promote', (req, res) => {
    const userId = req.params.id;
    db.query('UPDATE users SET role = "admin" WHERE id = ?', [userId], (err) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json({ success: true, message: 'Utilisateur promu en admin' });
    });
  });
  
  // ⬇️ Rétrograder un utilisateur
  app.patch('/users/:id/demote', (req, res) => {
    const userId = req.params.id;
    db.query('UPDATE users SET role = "user" WHERE id = ?', [userId], (err) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json({ success: true, message: 'Utilisateur rétrogradé en client' });
    });
  });
  
  // ✏️ Modifier les infos d’un utilisateur (email, nom, etc.)
  app.patch('/users/:id', (req, res) => {
    const userId = req.params.id;
    const updates = req.body; // Ex: { email: "nouveau@mail.com" }
    const fields = Object.keys(updates).map(field => `${field} = ?`).join(', ');
    const values = Object.values(updates);
  
    db.query(`UPDATE users SET ${fields} WHERE id = ?`, [...values, userId], (err) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json({ success: true, message: 'Utilisateur modifié avec succès' });
    });
  });
  

  // ✏️ Modifier les infos d’un produit (nom, prix, prix_promo, etc.)
app.patch('/products/:id', (req, res) => {
  const productId = req.params.id;
  const updates = req.body; // exemple: { nom: "Nouveau", prix: 150, prix_promo: 120 }

  if (!updates || Object.keys(updates).length === 0) {
    return res.status(400).json({ error: 'Aucune donnée à mettre à jour' });
  }

  const fields = Object.keys(updates).map(field => `${field} = ?`).join(', ');
  const values = Object.values(updates);

  const sql = `UPDATE produits SET ${fields} WHERE id = ?`;

  db.query(sql, [...values, productId], (err, result) => {
    if (err) {
      console.error('Erreur modification produit:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }

    res.json({ success: true, message: 'Produit mis à jour avec succès' });
  });
});

  // ❌ Supprimer un utilisateur
  app.delete('/users/:id', (req, res) => {
    const userId = req.params.id;
    db.query('DELETE FROM users WHERE id = ?', [userId], (err) => {
      if (err) return res.status(500).json({ error: 'Erreur serveur' });
      res.json({ success: true, message: 'Utilisateur supprimé' });
    });
  });

  app.post('/stock/approvisionnements', (req, res) => {
  const { produit_id, quantite, type_livraison, prix_total } = req.body;

  if (!produit_id || !quantite || !type_livraison || !prix_total) {
    return res.status(400).json({ error: 'Champs manquants' });
  }

  let dateReception = new Date();
  if (type_livraison === 'standard') {
    dateReception.setDate(dateReception.getDate() + 2);
  }

  const statut = type_livraison === 'express' ? 'reçue' : 'commandée';

  const sql = `
    INSERT INTO approvisionnements 
    (produit_id, quantite, type_livraison, prix_total, date_reception_prevue, statut)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.query(sql, [produit_id, quantite, type_livraison, prix_total, dateReception, statut], (err, result) => {
    if (err) {
      console.error('Erreur ajout approvisionnement:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }

    if (type_livraison === 'express') {
      db.query(
        'UPDATE produits SET stock = stock + ? WHERE id = ?',
        [quantite, produit_id],
        (err2) => {
          if (err2) {
            console.error('Erreur mise à jour stock express:', err2);
            return res.status(500).json({ error: 'Erreur stock' });
          }
          res.json({ success: true, insertedId: result.insertId });
        }
      );
    } else {
      res.json({ success: true, insertedId: result.insertId });
    }
  });
});

app.patch('/stock/approvisionnements/:id/statut', (req, res) => {
  const id = req.params.id;
  const { statut } = req.body;

  if (!statut) {
    return res.status(400).json({ error: 'Statut requis' });
  }

  const sql = 'UPDATE approvisionnements SET statut = ? WHERE id = ?';
  db.query(sql, [statut, id], (err, result) => {
    if (err) {
      console.error('Erreur mise à jour statut approvisionnement:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json({ success: true, message: 'Statut mis à jour' });
  });
});


  app.get('/stock/approvisionnements', (req, res) => {
  const sql = `
    SELECT a.*, p.nom AS produit_nom
    FROM approvisionnements a
    JOIN produits p ON a.produit_id = p.id
    ORDER BY a.date_commande DESC
  `;
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Erreur liste approvisionnements:', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json(results);
  });
});

  app.patch('/stock/approvisionnements/:id/valider', (req, res) => {
  const id = req.params.id;

  const updateStockSql = `
    UPDATE produits p
    JOIN approvisionnements a ON a.produit_id = p.id
    SET p.stock = p.stock + a.quantite
    WHERE a.id = ? AND a.statut = 'commandée'
  `;

  db.query(updateStockSql, [id], (err) => {
    if (err) {
      console.error('Erreur mise à jour stock:', err);
      return res.status(500).json({ error: 'Erreur stock' });
    }

    db.query(
      'UPDATE approvisionnements SET statut = "reçue" WHERE id = ?',
      [id],
      (err2) => {
        if (err2) {
          console.error('Erreur mise à jour statut:', err2);
          return res.status(500).json({ error: 'Erreur statut' });
        }
        res.json({ success: true });
      }
    );
  });
});

// 🔁 Vérifie chaque heure s'il faut réceptionner automatiquement
cron.schedule('0 * * * *', () => {
  console.log('⏰ Vérification des livraisons à réceptionner...');

  const sql = `
    UPDATE produits p
    JOIN approvisionnements a ON a.produit_id = p.id
    SET p.stock = p.stock + a.quantite, a.statut = 'reçue'
    WHERE a.type_livraison = 'standard'
      AND a.statut = 'commandée'
      AND a.date_reception_prevue <= NOW()
  `;

  db.query(sql, (err, result) => {
    if (err) {
      console.error('❌ Erreur mise à jour auto des stocks:', err);
    } else if (result.affectedRows > 0) {
      console.log(`✅ ${result.affectedRows} approvisionnement(s) mis à jour automatiquement`);
    }
  });
});
  
  app.get('/ventes', (req, res) => {
  const sql = `
    SELECT v.id, v.produit_id, v.quantite, v.total, v.date_vente,
           p.nom AS produit_nom,
           u.nom AS client_nom, u.prenom AS client_prenom,
           v.statut
    FROM ventes v
    JOIN produits p ON v.produit_id = p.id
    LEFT JOIN users u ON v.user_id = u.id
    WHERE v.date_vente >= NOW() - INTERVAL 61 DAY
    ORDER BY v.date_vente DESC
  `;
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Erreur récupération ventes :', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json(results);
  });
});

app.patch('/ventes/:id/statut', (req, res) => {
  const { id } = req.params;
  const { statut } = req.body;

  if (!statut) {
    return res.status(400).json({ error: 'Statut requis' });
  }

  db.query('UPDATE ventes SET statut = ? WHERE id = ?', [statut, id], (err, result) => {
    if (err) {
      console.error('Erreur update statut vente :', err);
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json({ success: true, message: 'Statut mis à jour' });
  });
});


// Lancer le serveur
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Serveur La League API en cours sur http://localhost:${port}`);
});
