CREATE TABLE IF NOT EXISTS cifra_santa_playlist (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id BIGINT UNSIGNED NOT NULL,
 titulo VARCHAR(120) NOT NULL,
 versao INT UNSIGNED NOT NULL DEFAULT 1,
 criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 FOREIGN KEY (usuario_id) REFERENCES cifra_santa_usuario(id) ON DELETE CASCADE,
 INDEX idx_cs_playlist_usuario (usuario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS cifra_santa_playlist_musica (
 playlist_id BIGINT UNSIGNED NOT NULL,
 musica_id BIGINT UNSIGNED NOT NULL,
 posicao INT UNSIGNED NOT NULL,
 PRIMARY KEY (playlist_id, musica_id),
 UNIQUE KEY idx_cs_playlist_ordem (playlist_id, posicao),
 FOREIGN KEY (playlist_id) REFERENCES cifra_santa_playlist(id) ON DELETE CASCADE,
 FOREIGN KEY (musica_id) REFERENCES cifra_santa_musica(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
