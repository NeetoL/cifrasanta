CREATE TABLE cifra_santa_biblia_livro (
 id VARCHAR(12) PRIMARY KEY,
 ordem TINYINT UNSIGNED NOT NULL UNIQUE,
 nome VARCHAR(120) NOT NULL,
 abreviacao VARCHAR(12) NOT NULL,
 testamento ENUM('antigo','novo') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cifra_santa_biblia_versiculo (
 livro_id VARCHAR(12) NOT NULL,
 capitulo SMALLINT UNSIGNED NOT NULL,
 versiculo SMALLINT UNSIGNED NOT NULL,
 texto TEXT NOT NULL,
 PRIMARY KEY (livro_id, capitulo, versiculo),
 FOREIGN KEY (livro_id) REFERENCES cifra_santa_biblia_livro(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
