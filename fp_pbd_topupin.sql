-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 28 Jul 2025 pada 17.55
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `topup`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetHighValueTransactions` ()   BEGIN
    -- Variabel untuk menampung data dari cursor
    DECLARE done INT DEFAULT FALSE;
    DECLARE t_code VARCHAR(255);
    DECLARE t_price INT;
    DECLARE t_game VARCHAR(255);

    -- Deklarasi Cursor untuk memilih transaksi mahal
    DECLARE cur_high_value_trans CURSOR FOR 
        SELECT transaction_code, game_name, price 
        FROM transactions 
        WHERE price > 500000;

    -- Handler untuk menghentikan loop ketika cursor selesai
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Membuat tabel temporary untuk menyimpan hasil
    CREATE TEMPORARY TABLE IF NOT EXISTS HighValueResults (
        message VARCHAR(512)
    );
    -- Mengosongkan tabel temporary sebelum digunakan
    TRUNCATE TABLE HighValueResults;

    OPEN cur_high_value_trans;

    read_loop: LOOP
        FETCH cur_high_value_trans INTO t_code, t_game, t_price;
        IF done THEN
            LEAVE read_loop;
        END IF;
        -- Memasukkan hasil format ke tabel temporary
        INSERT INTO HighValueResults(message) VALUES (CONCAT('Transaksi ', t_code, ' untuk game ', t_game, ' seharga Rp', t_price, ' adalah transaksi bernilai tinggi.'));
    END LOOP;

    CLOSE cur_high_value_trans;

    -- Menampilkan semua hasil dari tabel temporary
    SELECT * FROM HighValueResults;
    DROP TEMPORARY TABLE HighValueResults;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateGameName` (IN `p_game_id` BIGINT, IN `p_new_name` VARCHAR(255), OUT `p_old_name` VARCHAR(255))   BEGIN
    -- Menggunakan control flow IF untuk memeriksa apakah game ada
    IF EXISTS(SELECT 1 FROM games WHERE id = p_game_id) THEN
        -- Mengambil nama lama dan menyimpannya di parameter OUT
        SELECT name INTO p_old_name FROM games WHERE id = p_game_id;

        -- Memperbarui nama game
        UPDATE games SET name = p_new_name WHERE id = p_game_id;
    ELSE
        -- Jika game tidak ditemukan, set nama lama menjadi pesan error
        SET p_old_name = 'ERROR: Game ID not found.';
    END IF;
END$$

--
-- Fungsi
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CountItemsInPriceRange` (`p_game_id` BIGINT, `p_max_price` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE item_count INT;
    SELECT COUNT(*) INTO item_count
    FROM topup_items
    WHERE game_id = p_game_id AND price <= p_max_price;
    RETURN item_count;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `GetTotalCompletedRevenue` () RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE total_revenue INT;
    SELECT SUM(price) INTO total_revenue FROM transactions WHERE status = 'completed';
    RETURN total_revenue;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `accounts`
--

CREATE TABLE `accounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `game_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `status` enum('available','sold') NOT NULL DEFAULT 'available',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `archived_games`
--

CREATE TABLE `archived_games` (
  `id` bigint(20) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `archived_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `archived_games`
--

INSERT INTO `archived_games` (`id`, `name`, `slug`, `archived_at`) VALUES
(6, 'Roblox', 'roblox', '2025-07-28 14:23:11');

-- --------------------------------------------------------

--
-- Struktur dari tabel `audit_log`
--

CREATE TABLE `audit_log` (
  `id` int(11) NOT NULL,
  `log_entry` varchar(255) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `audit_log`
--

INSERT INTO `audit_log` (`id`, `log_entry`, `timestamp`) VALUES
(1, 'New transaction TPN-TESTING-001 for Rp14500 was created.', '2025-07-28 14:18:39');

-- --------------------------------------------------------

--
-- Struktur dari tabel `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `cheapvalorantitems`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `cheapvalorantitems` (
`id` bigint(20) unsigned
,`name` varchar(255)
,`price` int(10) unsigned
,`game_id` bigint(20) unsigned
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `danatransactions`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `danatransactions` (
`transaction_code` varchar(255)
,`game_name` varchar(255)
,`price` int(10) unsigned
,`status` enum('pending','completed','failed')
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `gamedisplayinfo`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `gamedisplayinfo` (
`name` varchar(255)
,`slug` varchar(255)
,`logo` varchar(255)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `games`
--

CREATE TABLE `games` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `thumbnail` varchar(255) DEFAULT NULL,
  `logo` varchar(255) DEFAULT NULL,
  `needs_server_id` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `games`
--

INSERT INTO `games` (`id`, `name`, `slug`, `thumbnail`, `logo`, `needs_server_id`, `created_at`, `updated_at`) VALUES
(1, 'Valorant', 'valorant', 'logovalo.png', 'valorant.jpg', 0, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(2, 'Clash of Clans', 'clash-of-clans', 'logococ.png', 'clashofclans.jpg', 0, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(3, 'Mobile Legends', 'mobile-legends', 'logomobile.png', 'mobilelegends.jpg', 1, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(4, 'Genshin Impact', 'genshin-impact', 'genshinimpact.jpg', 'genshintopup.jpeg', 1, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(5, 'Free Fire', 'free-fire', 'freefire.jpg', 'logoepep.png', 0, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(7, 'PUBG Mobile Indonesia', 'pubg', 'logopubg.png', 'pubgmobile.jpg', 1, '2025-07-28 06:48:13', '2025-07-28 06:48:13');

--
-- Trigger `games`
--
DELIMITER $$
CREATE TRIGGER `trg_before_game_delete` BEFORE DELETE ON `games` FOR EACH ROW BEGIN
    INSERT INTO archived_games(id, name, slug) 
    VALUES (OLD.id, OLD.name, OLD.slug);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2025_06_21_042946_create_transactions_table', 1),
(5, '2025_06_21_153633_create_games_table', 1),
(6, '2025_06_21_154303_create_topup_items_table', 1),
(7, '2025_06_21_154409_create_accounts_table', 1),
(8, '2025_06_22_173844_add_role_to_users_table', 1),
(9, '2025_07_14_033658_add_logo_to_games_table', 1),
(10, '2025_07_21_013036_add_image_to_topup_items_table', 1);

-- --------------------------------------------------------

--
-- Struktur dari tabel `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `ratings`
--

CREATE TABLE `ratings` (
  `id` int(11) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `game_id` bigint(20) UNSIGNED DEFAULT NULL,
  `rating_value` tinyint(4) DEFAULT NULL,
  `review` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `topup_items`
--

CREATE TABLE `topup_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `game_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `topup_items`
--

INSERT INTO `topup_items` (`id`, `game_id`, `name`, `price`, `image`, `created_at`, `updated_at`) VALUES
(1, 1, '53 VP', 15000, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(2, 1, '154 VP', 28500, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(3, 1, '256 VP', 45000, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(4, 1, '503 VP', 70000, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(5, 1, '1010 VP', 140000, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(6, 1, '2020 VP', 280000, 'valorant.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(7, 3, '86 Diamonds', 25000, 'diamondml.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(8, 3, '172 Diamonds', 50000, 'diamondml.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(9, 3, '257 Diamonds', 75000, 'diamondml.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(10, 2, '80 Gems', 15000, 'diamondcoc.png', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(11, 2, '500 Gems', 79000, 'diamondcoc.png', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(12, 2, '1200 Gems', 159000, 'diamondcoc.png', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(13, 4, '80 Genesis Crystals', 15000, 'primogem.webp', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(14, 4, '500 Genesis Crystals', 79000, 'primogem.webp', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(15, 4, '1200 Genesis Crystals', 159000, 'primogem.webp', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(16, 5, '80 Diamonds', 15000, 'diamondff.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(17, 5, '500 Diamonds', 79000, 'diamondff.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(18, 5, '1200 Diamonds', 159000, 'diamondff.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(22, 7, '80 UC', 15000, 'ucpubg.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(23, 7, '500 UC', 79000, 'ucpubg.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(24, 7, '1200 UC', 159000, 'ucpubg.jpg', '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(25, 5, '4650 Diamonds', 933212, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(26, 4, '4616 Diamonds', 233300, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(27, 7, '2499 Diamonds', 63420, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(28, 3, '964 UC', 780652, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(29, 7, '1979 UC', 139415, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(30, 4, '3416 Coins', 851023, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(31, 4, '3662 Gems', 601829, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(33, 2, '3532 UC', 601087, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(34, 1, '4976 Diamonds', 361328, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(35, 2, '1292 Coins', 85912, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(36, 2, '3830 UC', 833969, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(37, 1, '713 Coins', 918664, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(38, 7, '876 Gems', 290067, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(40, 3, '2312 Diamonds', 930940, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(41, 3, '3718 Gems', 450140, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(43, 5, '653 Coins', 387318, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(44, 1, '2485 Coins', 500031, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(45, 2, '2851 UC', 358900, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(46, 4, '3847 Diamonds', 71936, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(47, 7, '518 Diamonds', 373534, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(48, 1, '236 Gems', 722368, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(49, 2, '1977 UC', 262868, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(50, 5, '183 Diamonds', 182758, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(51, 3, '4486 Diamonds', 169846, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(52, 3, '776 Coins', 864723, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(53, 7, '3979 UC', 345769, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(54, 3, '4172 UC', 41525, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(56, 5, '1147 Diamonds', 449322, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(57, 1, '700 UC', 805931, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(58, 2, '2761 Coins', 211896, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(59, 1, '2377 Diamonds', 420971, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(60, 4, '1507 UC', 622533, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(61, 4, '3968 Diamonds', 320208, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(62, 4, '1090 Coins', 225029, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(63, 7, '3254 Gems', 293943, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(64, 3, '4656 Gems', 449508, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(66, 4, '3118 UC', 861485, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(68, 4, '4044 Gems', 185517, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(69, 3, '2736 Gems', 389121, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(70, 4, '2718 Gems', 746623, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(71, 5, '1868 Diamonds', 384010, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(72, 5, '1300 Diamonds', 296458, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(73, 7, '2161 Coins', 523025, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(74, 4, '4486 Diamonds', 765848, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(75, 7, '693 UC', 142763, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(76, 3, '3517 Diamonds', 520505, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(77, 1, '4186 Diamonds', 476649, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(78, 1, '3375 Gems', 839363, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(79, 5, '2718 Diamonds', 536841, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(80, 3, '4590 Gems', 818421, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(81, 7, '1368 Gems', 541912, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(82, 7, '579 Coins', 227319, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(83, 4, '2124 Diamonds', 809016, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(84, 4, '4111 Coins', 733484, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(85, 7, '4538 Coins', 391838, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(86, 3, '2226 Diamonds', 691331, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(87, 5, '4071 Gems', 359416, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(88, 2, '2199 UC', 763937, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(89, 5, '3292 Coins', 408074, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(91, 5, '3479 Gems', 548309, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(92, 2, '243 Diamonds', 906115, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(93, 2, '1194 Gems', 90045, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(94, 1, '4801 Gems', 141377, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(95, 5, '1863 Gems', 342616, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(97, 5, '952 Diamonds', 786191, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(100, 5, '4001 Diamonds', 438875, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(101, 7, '2493 UC', 868471, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(102, 4, '222 Coins', 244516, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(103, 2, '2732 Coins', 218622, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(104, 7, '217 Coins', 891456, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(106, 7, '1145 Diamonds', 47095, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(107, 2, '1943 UC', 22535, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(108, 5, '4666 Gems', 602186, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(109, 2, '398 Gems', 540859, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(110, 4, '3638 Diamonds', 861447, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(111, 5, '1760 Coins', 817932, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(112, 4, '3604 Coins', 452991, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(113, 7, '1062 Coins', 727332, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(114, 4, '3745 UC', 452498, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(116, 1, '1528 Diamonds', 94748, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(117, 1, '1836 UC', 276932, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(118, 1, '1132 Coins', 53522, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(119, 1, '2704 Diamonds', 393050, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(120, 4, '2121 Coins', 827450, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(121, 1, '3674 Gems', 116332, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(122, 1, '818 Diamonds', 679208, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(123, 5, '4827 Gems', 762817, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(124, 1, '226 Diamonds', 465489, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(126, 4, '4608 Diamonds', 57507, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(127, 4, '2842 UC', 363581, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(128, 7, '102 Coins', 843634, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(129, 4, '4971 Diamonds', 626817, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(130, 7, '3024 UC', 755130, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(131, 1, '920 UC', 251679, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(132, 5, '1412 Diamonds', 196316, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(134, 1, '1151 Gems', 434849, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(135, 4, '3945 Gems', 239920, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(138, 2, '2606 Gems', 544480, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(139, 2, '3315 Coins', 902059, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(140, 7, '2064 Coins', 902987, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(141, 3, '4908 UC', 203423, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(142, 1, '2272 Coins', 943096, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(143, 5, '3566 Coins', 647332, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(144, 3, '282 Diamonds', 804245, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(145, 7, '3748 Gems', 471541, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(146, 7, '4038 Diamonds', 569440, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(147, 2, '4752 Diamonds', 438087, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(148, 4, '687 Coins', 529687, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(149, 2, '1541 Coins', 768419, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(150, 7, '3650 Diamonds', 435225, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(152, 4, '2158 Diamonds', 147469, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(153, 2, '405 Diamonds', 465146, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(154, 1, '2686 Coins', 454694, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(155, 1, '2693 UC', 655339, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(156, 3, '216 UC', 799791, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(157, 3, '1181 Coins', 274162, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(158, 5, '2710 Gems', 509827, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(159, 7, '933 Gems', 345092, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(160, 3, '4470 Gems', 875612, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(161, 5, '4642 Coins', 364794, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(162, 1, '2100 Coins', 958391, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(163, 1, '3326 UC', 765004, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(165, 7, '3848 UC', 98640, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(166, 5, '1059 UC', 93477, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(167, 4, '1849 Gems', 277429, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(170, 3, '3528 Coins', 366336, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(171, 2, '709 Coins', 674812, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(172, 4, '348 UC', 356397, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(173, 5, '3880 Gems', 958710, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(174, 4, '4985 Coins', 259519, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(175, 2, '2359 Coins', 891496, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(176, 1, '870 UC', 372926, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(177, 1, '1980 Diamonds', 901291, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(178, 2, '3217 Gems', 238526, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(179, 2, '2240 Gems', 847209, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(181, 5, '1311 Diamonds', 314553, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(182, 7, '4869 UC', 335934, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(183, 7, '4019 Gems', 537212, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(184, 4, '2454 Diamonds', 67532, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(185, 3, '3972 UC', 520971, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(186, 4, '4347 Coins', 672957, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(187, 5, '3249 UC', 781250, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(188, 5, '1279 Gems', 348777, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(190, 2, '4841 Coins', 382955, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(191, 2, '1565 Gems', 261197, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(192, 4, '4867 Diamonds', 826838, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(193, 3, '4214 Coins', 25201, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(194, 7, '1858 Gems', 546965, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(195, 2, '2937 Coins', 757825, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(196, 5, '727 Coins', 585667, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(197, 3, '2673 UC', 37632, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(198, 2, '3528 Diamonds', 166428, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(199, 3, '1202 Gems', 457017, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(200, 7, '1417 Diamonds', 739626, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(201, 4, '1941 Coins', 922706, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(202, 1, '4388 UC', 893463, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(203, 3, '3654 Diamonds', 171224, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(204, 4, '4090 Diamonds', 741771, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(205, 4, '2613 Gems', 653121, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(206, 2, '314 Diamonds', 453850, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(207, 2, '2289 Gems', 848732, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(208, 3, '2599 UC', 225142, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(209, 5, '3694 Diamonds', 539839, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(210, 4, '1862 Diamonds', 673348, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(212, 3, '4735 Gems', 513217, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(213, 7, '4624 UC', 606031, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(214, 5, '1014 Coins', 693927, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(215, 1, '1670 Gems', 475823, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(216, 1, '443 Coins', 615558, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(218, 1, '722 Diamonds', 316328, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(219, 7, '909 Coins', 336124, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(220, 4, '3754 Coins', 621390, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(221, 2, '2053 Diamonds', 191187, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(222, 1, '1350 Gems', 823591, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(223, 5, '553 UC', 252188, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(224, 2, '4306 Coins', 624839, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(226, 4, '177 UC', 365109, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(228, 3, '2705 Diamonds', 412867, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(230, 1, '272 UC', 968578, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(231, 7, '2309 Gems', 570788, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(232, 4, '2266 UC', 145760, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(233, 5, '835 Coins', 938326, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(234, 7, '1657 Coins', 368842, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(236, 3, '899 Diamonds', 598165, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(237, 2, '3465 Gems', 824231, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(238, 3, '124 Diamonds', 972923, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(239, 1, '3575 Gems', 715962, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(240, 7, '1440 Gems', 141557, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(241, 7, '3466 Diamonds', 193137, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(242, 5, '3700 Diamonds', 350306, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(244, 5, '1029 Gems', 891898, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(245, 5, '4973 UC', 627593, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(246, 2, '4362 Coins', 380983, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(247, 3, '1674 Diamonds', 895505, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(248, 2, '3136 Diamonds', 811309, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(250, 1, '3496 UC', 415188, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(252, 2, '1828 UC', 121758, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(253, 4, '4104 Gems', 900159, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(254, 3, '1513 Diamonds', 713971, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(255, 7, '4699 Diamonds', 449428, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(256, 4, '2439 Diamonds', 721603, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(257, 2, '1323 Diamonds', 140097, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(258, 1, '3469 Coins', 898169, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(259, 4, '4964 Diamonds', 466493, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(260, 1, '4117 Coins', 249599, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(261, 5, '4686 Coins', 826096, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(262, 3, '1801 UC', 247672, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(263, 7, '3542 Diamonds', 499888, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(265, 1, '2403 Diamonds', 531079, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(266, 7, '397 Diamonds', 219440, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(267, 7, '2209 UC', 25562, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(268, 2, '1183 Gems', 414211, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(269, 4, '358 UC', 876068, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(270, 3, '4876 Coins', 224631, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(271, 7, '1890 Gems', 710886, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(272, 2, '1427 Gems', 872473, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(273, 1, '3526 Coins', 324914, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(274, 1, '1127 Diamonds', 573813, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(275, 2, '1221 Diamonds', 193651, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(276, 7, '1174 Gems', 311481, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(277, 5, '2974 UC', 412403, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(278, 2, '2593 UC', 227982, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(279, 5, '4179 Gems', 449571, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(280, 2, '3732 Gems', 572124, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(282, 3, '1820 Coins', 911611, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(283, 1, '1291 Coins', 200166, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(284, 3, '835 Coins', 482561, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(285, 2, '1550 Coins', 193241, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(286, 1, '2397 Coins', 245555, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(287, 3, '2174 UC', 980663, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(288, 4, '1545 UC', 35098, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(289, 5, '3127 Gems', 572273, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(290, 1, '1387 Gems', 496374, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(291, 4, '406 Coins', 216643, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(292, 4, '3355 Coins', 568670, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(293, 2, '658 Gems', 812186, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(294, 7, '4336 Diamonds', 915704, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(295, 3, '1275 Diamonds', 56523, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(296, 1, '1654 Diamonds', 229777, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(297, 7, '306 Coins', 615882, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(298, 2, '4553 Gems', 258101, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(299, 4, '4231 Coins', 136667, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(300, 3, '4806 Coins', 97034, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(301, 1, '1746 Diamonds', 173335, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(302, 3, '3545 Diamonds', 517905, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(303, 5, '4869 UC', 537687, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(304, 3, '4996 Diamonds', 479703, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(305, 3, '4754 UC', 342323, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(307, 1, '3988 UC', 946742, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(310, 4, '3825 Coins', 903055, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(311, 3, '3613 Diamonds', 589372, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(312, 2, '2403 UC', 225659, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(313, 5, '403 Gems', 208034, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(314, 2, '1360 Coins', 774127, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(315, 5, '101 Diamonds', 504329, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(316, 5, '1656 Gems', 20638, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(317, 4, '3214 UC', 923155, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(318, 4, '1400 Coins', 156512, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(320, 4, '1976 Diamonds', 161622, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(321, 4, '622 Gems', 586092, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(322, 5, '2227 Gems', 25441, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(323, 5, '3364 Gems', 260400, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(324, 3, '1714 UC', 151393, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(325, 4, '3960 Coins', 750931, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(326, 2, '4850 Diamonds', 639821, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(327, 4, '3681 Gems', 909724, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(328, 2, '2986 Gems', 485787, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(329, 4, '583 Gems', 836861, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(330, 5, '4453 Diamonds', 345134, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(331, 2, '4963 UC', 882338, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(332, 1, '969 Diamonds', 894744, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(334, 5, '2904 UC', 897146, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(335, 4, '2574 Coins', 846309, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(336, 2, '1742 Gems', 493381, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(338, 4, '2038 Coins', 568585, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(339, 5, '4708 Gems', 403761, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(340, 7, '492 Diamonds', 367522, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(341, 3, '2191 Coins', 710789, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(342, 7, '1601 Diamonds', 128871, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(343, 7, '3503 UC', 128324, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(344, 2, '1536 Diamonds', 757753, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(345, 7, '1872 UC', 366253, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(346, 5, '4403 UC', 771188, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(347, 1, '4041 UC', 895619, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(348, 5, '2616 Coins', 691916, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(349, 2, '3648 Gems', 745960, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(350, 1, '4790 Gems', 45566, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(351, 2, '2054 Coins', 938122, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(352, 3, '3263 Gems', 499768, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(353, 4, '2808 Coins', 628792, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(354, 7, '2076 UC', 971400, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(355, 1, '2706 Gems', 841055, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(356, 5, '4022 Diamonds', 333256, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(357, 4, '216 Diamonds', 792719, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(358, 7, '188 Coins', 578905, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(360, 4, '4109 UC', 385962, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(361, 3, '1658 Gems', 268342, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(362, 2, '2568 Diamonds', 902342, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(363, 3, '146 Coins', 54545, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(364, 7, '3070 Diamonds', 709893, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(366, 4, '2371 Gems', 773121, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(367, 1, '3768 UC', 128151, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(368, 2, '2386 UC', 748489, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(369, 3, '2926 Diamonds', 856504, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(370, 4, '3364 Diamonds', 183438, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(371, 3, '3883 Gems', 336985, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(372, 7, '788 Diamonds', 507936, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(373, 1, '3502 UC', 991444, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(374, 3, '2748 Coins', 165950, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(375, 1, '1630 Gems', 642068, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(376, 2, '1186 Gems', 261131, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(377, 4, '2021 Gems', 482402, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(378, 4, '1462 Coins', 954867, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(379, 7, '433 Diamonds', 31040, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(380, 4, '2358 UC', 964226, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(381, 7, '4915 Diamonds', 562705, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(382, 3, '4906 UC', 348076, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(383, 3, '2945 Gems', 520239, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(384, 7, '3407 Diamonds', 675237, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(385, 4, '3484 Diamonds', 685251, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(386, 7, '2267 Coins', 347381, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(387, 2, '3501 UC', 650427, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(388, 5, '856 Diamonds', 914737, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(389, 4, '661 Coins', 61554, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(390, 3, '4894 Gems', 728474, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(391, 4, '4313 Coins', 908391, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(392, 1, '1546 Gems', 603201, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(393, 1, '4873 Gems', 517910, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(395, 1, '2715 Gems', 759188, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(396, 2, '3786 Diamonds', 215471, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(398, 4, '1833 Gems', 95307, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(400, 7, '2151 Coins', 370667, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(402, 4, '2122 UC', 361929, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(403, 1, '1152 Coins', 531257, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(404, 4, '2156 Diamonds', 315275, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(405, 1, '706 UC', 520215, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(406, 1, '778 Diamonds', 854539, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(407, 1, '3641 UC', 659946, 'items/default.png', '2025-07-28 06:48:15', '2025-07-28 06:48:15'),
(409, 1, '4025 UC', 218883, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(410, 4, '899 Diamonds', 83853, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(411, 2, '1511 UC', 254964, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(412, 2, '2599 Diamonds', 517177, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(413, 1, '1878 Coins', 743941, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(415, 3, '1369 Coins', 904125, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(418, 4, '277 Gems', 572186, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(419, 7, '1609 UC', 350387, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(422, 3, '3171 UC', 460602, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(423, 7, '4982 UC', 850483, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(424, 3, '1193 UC', 939044, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(425, 2, '1146 Gems', 760323, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(426, 5, '2829 Diamonds', 158712, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(427, 1, '1506 UC', 299917, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(428, 3, '787 UC', 245694, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(429, 5, '2242 UC', 470157, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(430, 3, '3577 Gems', 370518, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(431, 4, '3091 Coins', 581542, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(432, 3, '1053 Diamonds', 952972, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(433, 1, '2449 Coins', 555147, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(434, 5, '2835 Diamonds', 298860, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(435, 4, '3063 Diamonds', 284827, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(436, 5, '3557 Coins', 625093, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(437, 2, '3611 UC', 826816, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(438, 7, '1875 Diamonds', 658235, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(439, 1, '2396 Coins', 936029, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(440, 3, '782 Gems', 292667, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(441, 1, '3840 Coins', 402942, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(442, 3, '3934 Gems', 962350, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(443, 1, '4696 Coins', 111175, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(444, 4, '4016 Coins', 805381, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(445, 7, '4388 Coins', 408887, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(446, 1, '1089 UC', 11221, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(447, 3, '1717 Diamonds', 859087, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(448, 1, '3838 Diamonds', 888097, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(449, 3, '1591 UC', 300694, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(450, 2, '3260 Diamonds', 705711, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(451, 5, '2088 UC', 567138, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(453, 2, '1942 UC', 744215, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(455, 3, '2431 Diamonds', 314526, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(456, 5, '3348 UC', 95360, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(457, 3, '3729 Gems', 765877, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(458, 2, '1125 Diamonds', 198014, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(460, 2, '301 Diamonds', 141749, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(461, 7, '797 Coins', 906413, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(465, 7, '1725 UC', 991282, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(466, 3, '2636 Coins', 356115, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(467, 5, '2384 Gems', 471414, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(468, 5, '2331 Gems', 92302, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(469, 2, '2299 Coins', 20508, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(470, 5, '3236 Gems', 560749, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(471, 1, '1249 Diamonds', 926140, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(472, 3, '3366 Diamonds', 21030, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(473, 2, '348 UC', 465524, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(474, 1, '4199 Gems', 946443, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(475, 5, '248 Gems', 139863, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(477, 1, '4793 UC', 196954, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(478, 5, '1785 UC', 702962, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(479, 3, '2690 Diamonds', 64114, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(480, 2, '1849 Coins', 825129, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(481, 5, '714 Diamonds', 225897, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(483, 5, '1231 Coins', 556040, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(484, 3, '2342 Gems', 481499, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(485, 1, '3710 Diamonds', 228880, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(486, 2, '4927 UC', 243806, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(487, 1, '4691 Coins', 815238, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(488, 5, '4066 UC', 489665, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(489, 1, '191 UC', 543745, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(490, 7, '1940 UC', 619326, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(491, 7, '625 UC', 732667, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(492, 4, '2385 Coins', 507483, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(494, 5, '4610 UC', 986325, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(495, 2, '117 UC', 879257, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(496, 2, '4288 Diamonds', 392560, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(497, 5, '2003 UC', 185239, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(498, 1, '678 Coins', 557488, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(499, 3, '2377 Coins', 318988, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(500, 4, '3689 Coins', 354380, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(501, 7, '1956 Coins', 36442, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(502, 1, '3781 Diamonds', 186357, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(503, 2, '1236 Coins', 483813, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(504, 7, '4951 UC', 437881, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(505, 2, '272 Coins', 182413, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(506, 3, '1593 UC', 941691, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(507, 1, '3753 UC', 699187, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(509, 3, '570 Diamonds', 334280, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(512, 7, '4396 Coins', 74799, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(513, 5, '711 Coins', 379190, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(514, 4, '520 Diamonds', 229049, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(515, 5, '2958 Gems', 77419, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(516, 2, '835 Diamonds', 727567, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(517, 3, '1602 UC', 789332, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(518, 5, '4761 Coins', 128397, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(520, 4, '818 Diamonds', 218619, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(521, 2, '2097 UC', 396209, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(522, 4, '4084 Gems', 955291, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(523, 1, '3425 Diamonds', 437303, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(525, 7, '4023 UC', 756700, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(526, 3, '1344 UC', 481863, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(527, 7, '2620 UC', 270570, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(528, 3, '228 Coins', 770651, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(530, 2, '2840 Gems', 897067, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(531, 5, '3983 UC', 285846, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(532, 1, '4574 Gems', 807189, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(533, 5, '857 Diamonds', 362304, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(535, 7, '4083 Gems', 570359, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(536, 4, '4635 Gems', 343548, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(537, 7, '3590 Diamonds', 846253, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(538, 7, '365 Diamonds', 654120, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(539, 2, '4220 Coins', 342291, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(540, 1, '109 Coins', 452483, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(541, 7, '3904 Diamonds', 731516, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(542, 4, '1583 Diamonds', 39445, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(543, 1, '4329 UC', 860409, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(544, 5, '3303 UC', 334936, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(545, 3, '2619 Gems', 908607, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(546, 3, '659 UC', 973146, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(547, 7, '2041 UC', 762787, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(548, 2, '3898 Coins', 759880, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(549, 5, '2808 Diamonds', 534793, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(550, 2, '3992 Gems', 900626, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(551, 2, '1344 Coins', 456599, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(552, 4, '200 Gems', 457473, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(553, 2, '1034 Gems', 632497, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(554, 2, '3089 Gems', 270790, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(555, 7, '338 UC', 302887, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(556, 2, '4839 Gems', 596292, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(557, 4, '1741 Gems', 283807, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(558, 1, '4623 UC', 335028, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(559, 4, '1978 Coins', 220349, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(560, 4, '1538 Coins', 462277, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(561, 5, '3621 Coins', 826197, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(562, 7, '499 Coins', 310003, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(563, 7, '1037 Coins', 483799, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(564, 3, '4851 UC', 311687, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(565, 7, '3256 Diamonds', 136170, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(566, 3, '3554 UC', 111875, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(567, 3, '4574 Coins', 439595, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(569, 1, '284 Gems', 534856, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(570, 5, '4793 Gems', 613166, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(571, 4, '3020 Coins', 196285, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(572, 5, '394 Coins', 83274, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(573, 3, '4864 Diamonds', 447357, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(574, 4, '3311 Coins', 171963, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(576, 5, '727 Coins', 575567, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(577, 4, '2237 Gems', 234175, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(578, 7, '790 Diamonds', 136906, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(580, 7, '719 Coins', 961589, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(581, 2, '1692 Diamonds', 491297, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(582, 5, '339 UC', 693109, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(583, 2, '4237 Coins', 263877, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(584, 2, '1533 Gems', 22222, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(585, 1, '1729 Diamonds', 973898, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(586, 7, '1099 Diamonds', 377428, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(587, 7, '3760 Gems', 323620, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(588, 2, '4132 Coins', 180095, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(589, 5, '1402 Diamonds', 497411, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(590, 2, '1066 Coins', 539203, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(591, 7, '4559 Coins', 91877, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16');
INSERT INTO `topup_items` (`id`, `game_id`, `name`, `price`, `image`, `created_at`, `updated_at`) VALUES
(592, 1, '222 Diamonds', 369674, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(593, 1, '281 Gems', 826894, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(594, 4, '4608 Gems', 250906, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(595, 2, '4269 Coins', 652522, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(596, 2, '1237 Gems', 977669, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(597, 1, '4058 Gems', 910939, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(598, 1, '4593 Diamonds', 502700, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(599, 2, '4898 Coins', 482632, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(600, 2, '2184 Coins', 320665, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(601, 4, '3727 Gems', 946205, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(602, 1, '2581 Coins', 250770, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(603, 7, '1825 Coins', 496717, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(604, 3, '4956 Diamonds', 751207, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(605, 7, '4250 UC', 661703, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(606, 4, '2182 Gems', 577790, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(607, 5, '2087 Coins', 812391, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(608, 7, '4217 UC', 539971, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(609, 4, '1413 Gems', 665737, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(611, 2, '564 Diamonds', 162622, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(612, 5, '1470 Diamonds', 983136, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(613, 3, '3131 Diamonds', 197779, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(614, 7, '3753 Coins', 45422, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(615, 3, '1714 Coins', 466412, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(616, 3, '795 Coins', 332963, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(617, 2, '4913 UC', 843385, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(618, 1, '617 Coins', 780586, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(619, 1, '4771 Coins', 719475, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(620, 3, '2248 Coins', 680264, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(621, 7, '4280 Diamonds', 31083, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(622, 4, '332 Coins', 650545, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(623, 2, '2228 Gems', 699886, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(624, 4, '1641 Gems', 532863, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(625, 2, '2055 Diamonds', 262576, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(626, 7, '2035 Gems', 251225, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(627, 4, '2888 Gems', 327813, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(629, 2, '4145 UC', 581817, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(630, 7, '1712 Gems', 675357, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(631, 5, '4130 UC', 670065, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(632, 1, '1197 Coins', 140581, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(633, 2, '4805 UC', 889053, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(634, 1, '2992 Gems', 18145, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(635, 3, '4033 Diamonds', 555535, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(636, 3, '3963 Diamonds', 150689, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(637, 5, '2146 Gems', 709409, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(638, 2, '3473 Diamonds', 260697, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(639, 5, '3452 Coins', 27109, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(640, 3, '512 Diamonds', 238434, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(641, 1, '3513 Coins', 613413, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(642, 2, '3459 Coins', 944082, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(643, 2, '237 Diamonds', 662318, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(644, 4, '2467 Diamonds', 366498, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(645, 4, '1655 UC', 109242, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(646, 3, '4552 Diamonds', 790082, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(647, 5, '4214 Diamonds', 279375, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(648, 1, '3437 Diamonds', 963035, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(649, 2, '3834 Gems', 311108, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(651, 2, '521 UC', 34599, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(652, 3, '2610 Coins', 233380, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(653, 1, '436 Diamonds', 78661, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(654, 1, '2327 Diamonds', 531359, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(655, 5, '2627 Gems', 606181, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(657, 5, '2209 Coins', 238599, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(658, 4, '2965 Gems', 536004, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(659, 4, '2558 Gems', 245252, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(660, 7, '604 Gems', 714234, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(662, 3, '1330 Diamonds', 26923, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(663, 7, '549 Gems', 736013, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(664, 1, '2636 Coins', 976953, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(665, 4, '4661 Coins', 292202, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(666, 4, '4689 UC', 292008, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(668, 4, '2974 Coins', 227387, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(669, 7, '4553 Coins', 283739, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(670, 5, '2659 Coins', 204874, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(672, 2, '2699 UC', 762052, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(673, 7, '2193 Gems', 432120, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(675, 7, '4606 Coins', 915940, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(676, 7, '4426 Gems', 925358, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(679, 4, '4085 Gems', 346043, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(680, 7, '4478 Coins', 703684, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(681, 3, '391 Gems', 537467, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(682, 5, '1649 Diamonds', 418996, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(683, 1, '800 UC', 989787, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(684, 4, '3537 UC', 291896, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(685, 1, '3706 Diamonds', 901925, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(686, 3, '256 UC', 915158, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(687, 2, '382 Gems', 926554, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(688, 2, '3350 Diamonds', 743569, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(689, 7, '2995 UC', 817524, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(690, 3, '2496 Gems', 392203, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(691, 2, '743 Gems', 472384, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(693, 5, '1166 Coins', 402055, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(695, 1, '3239 Gems', 356422, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(696, 2, '4487 Gems', 330470, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(697, 7, '2283 Coins', 776941, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(698, 2, '2027 Coins', 268477, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(699, 5, '2172 Gems', 323277, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(700, 3, '1443 UC', 873884, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(701, 7, '4036 Coins', 728733, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(702, 4, '2294 Diamonds', 465951, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(703, 1, '1388 UC', 227751, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(704, 5, '2098 UC', 509003, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(706, 1, '2497 Diamonds', 342728, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(707, 7, '2184 UC', 745099, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(708, 5, '2441 Gems', 253904, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(709, 4, '1451 Diamonds', 155449, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(711, 1, '390 Diamonds', 510269, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(712, 7, '4999 UC', 111687, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(713, 3, '803 UC', 676182, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(714, 3, '853 Gems', 573570, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(715, 5, '4348 Diamonds', 156188, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(716, 1, '104 Diamonds', 859649, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(717, 1, '1880 Coins', 469766, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(718, 5, '1658 UC', 888176, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(719, 2, '665 Coins', 465713, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(721, 7, '4089 Diamonds', 924127, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(722, 4, '4238 Coins', 342266, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(723, 1, '4599 Gems', 737615, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(724, 7, '2300 Diamonds', 199708, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(725, 1, '1836 Coins', 617003, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(726, 7, '4635 Diamonds', 236630, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(727, 1, '1903 UC', 638211, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(728, 1, '3079 Coins', 507477, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(729, 3, '1154 Gems', 960879, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(731, 2, '3492 Diamonds', 266010, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(732, 1, '927 Gems', 648173, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(733, 7, '3108 Diamonds', 949758, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(734, 2, '1924 Diamonds', 269155, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(735, 1, '4637 Diamonds', 693906, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(736, 3, '2465 UC', 53823, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(737, 1, '1720 Gems', 240437, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(739, 4, '4107 Gems', 757727, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(740, 5, '2353 Diamonds', 961388, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(741, 1, '3373 Gems', 848563, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(742, 2, '3011 UC', 387920, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(743, 4, '3384 Coins', 342893, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(744, 7, '3270 Gems', 470499, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(745, 7, '4356 Coins', 196227, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(746, 3, '967 Diamonds', 789337, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(747, 1, '2551 Coins', 728424, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(748, 1, '446 Gems', 941003, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(749, 3, '2223 Gems', 328368, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(750, 1, '3234 UC', 405020, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(751, 1, '4690 Gems', 941144, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(752, 1, '1140 Gems', 36912, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(753, 4, '270 Diamonds', 52418, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(754, 3, '2394 Gems', 947776, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(755, 3, '3272 Diamonds', 666522, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(757, 1, '2287 Coins', 78102, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(758, 1, '2964 Gems', 54511, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(759, 3, '1030 Coins', 647453, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(761, 5, '444 Diamonds', 314254, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(762, 5, '321 Coins', 690080, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(763, 3, '1941 Coins', 863359, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(764, 1, '3493 Coins', 844163, 'items/default.png', '2025-07-28 06:48:16', '2025-07-28 06:48:16'),
(765, 5, '3434 Coins', 427870, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(766, 5, '3183 UC', 987441, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(767, 3, '1276 Coins', 890327, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(768, 4, '3175 Gems', 761592, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(769, 1, '363 Gems', 765454, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(770, 4, '1522 UC', 842923, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(771, 2, '2579 Coins', 371752, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(772, 1, '4264 Diamonds', 104413, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(773, 2, '1179 Diamonds', 75355, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(774, 5, '956 UC', 154275, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(775, 2, '3063 Gems', 859237, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(776, 7, '1853 UC', 76882, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(777, 5, '349 Gems', 618214, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(778, 7, '2720 Gems', 529987, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(779, 5, '1116 Gems', 248508, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(780, 3, '273 Diamonds', 889744, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(781, 3, '2910 Gems', 750535, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(782, 2, '2641 Diamonds', 610511, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(784, 1, '2966 Coins', 124037, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(785, 2, '2358 UC', 353587, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(786, 5, '4563 Coins', 387182, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(787, 4, '4954 UC', 308531, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(788, 1, '2539 Diamonds', 913019, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(789, 1, '2030 Diamonds', 603968, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(790, 1, '3864 Diamonds', 631051, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(791, 4, '2076 UC', 124442, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(793, 4, '431 UC', 603625, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(794, 5, '4556 Gems', 870829, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(795, 3, '4489 UC', 276030, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(796, 2, '2356 UC', 395593, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(797, 3, '2910 UC', 835807, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(801, 1, '5000 Gems', 577720, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(802, 3, '2388 UC', 959801, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(803, 5, '3372 Gems', 761024, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(804, 4, '3596 Gems', 890633, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(805, 7, '4815 Diamonds', 985454, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(807, 3, '703 Diamonds', 455301, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(808, 1, '1679 Coins', 267077, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(810, 3, '880 Diamonds', 356463, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(811, 5, '3501 Coins', 424363, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(812, 1, '276 Diamonds', 929620, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(813, 3, '3570 Diamonds', 588790, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(814, 5, '1203 Gems', 650185, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(815, 3, '1952 Gems', 75089, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(816, 1, '2309 Gems', 269816, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(817, 2, '1551 Gems', 671363, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(818, 1, '3185 Diamonds', 25822, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(819, 7, '1083 Coins', 265955, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(820, 1, '1681 Diamonds', 446594, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(821, 5, '752 UC', 900321, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(823, 5, '1078 Gems', 288628, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(824, 4, '4166 UC', 584608, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(825, 2, '4428 Coins', 949750, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(826, 3, '1391 Gems', 718809, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(827, 5, '4474 Coins', 577340, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(828, 2, '1710 Diamonds', 243538, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(832, 2, '501 UC', 291676, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(833, 3, '2511 UC', 588386, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(834, 5, '4849 UC', 558061, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(835, 1, '3489 Diamonds', 549362, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(836, 4, '3031 Diamonds', 856309, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(837, 5, '4247 Gems', 647833, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(838, 5, '608 Coins', 981621, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(839, 3, '626 Diamonds', 540948, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(841, 5, '3658 Diamonds', 928619, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(842, 5, '4230 UC', 918700, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(843, 7, '1920 Diamonds', 627814, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(845, 5, '3371 Coins', 627831, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(846, 4, '4534 Coins', 323305, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(847, 3, '3199 Gems', 186643, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(850, 2, '2184 Gems', 628292, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(853, 3, '3113 Coins', 286137, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(854, 2, '3346 Diamonds', 120947, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(855, 1, '3059 Diamonds', 923558, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(857, 5, '754 Coins', 906507, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(858, 4, '1741 UC', 964940, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(859, 4, '3682 Coins', 758016, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(860, 4, '3466 Gems', 812116, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(861, 5, '2909 Diamonds', 653433, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(863, 7, '1017 Gems', 572165, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(864, 4, '4505 UC', 566224, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(865, 2, '4572 UC', 589194, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(866, 2, '4226 UC', 239312, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(867, 2, '930 Diamonds', 619766, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(868, 2, '2389 UC', 68025, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(869, 2, '3875 UC', 870783, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(870, 7, '1490 Diamonds', 395273, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(871, 5, '3023 Diamonds', 605113, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(872, 5, '1577 Coins', 459636, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(873, 5, '2948 UC', 781249, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(874, 1, '3872 UC', 234608, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(875, 2, '4992 UC', 160680, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(876, 1, '3936 Diamonds', 597964, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(877, 4, '4508 Coins', 548970, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(878, 2, '3590 Coins', 861916, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(879, 2, '1830 Gems', 933117, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(880, 4, '3556 UC', 281392, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(881, 1, '470 Gems', 657212, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(882, 4, '4068 Coins', 488009, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(883, 1, '585 Coins', 981185, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(885, 5, '3425 Coins', 369588, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(886, 2, '489 Coins', 933857, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(887, 7, '3858 UC', 511733, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(888, 4, '564 Coins', 874416, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(890, 4, '3596 Coins', 569278, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(891, 7, '4030 Gems', 882688, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(892, 4, '2834 Coins', 480431, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(893, 7, '3843 Diamonds', 765741, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(894, 7, '2015 Coins', 859411, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(896, 7, '693 Diamonds', 279012, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(897, 3, '2589 UC', 562146, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(898, 1, '3543 Coins', 732014, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(899, 4, '4577 Coins', 434481, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(900, 7, '4166 Diamonds', 913565, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(901, 7, '2617 Gems', 241646, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(902, 2, '3388 UC', 421812, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(903, 1, '1303 Diamonds', 884918, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(904, 5, '1165 Gems', 209419, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(905, 1, '3006 Diamonds', 813504, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(906, 1, '4711 Coins', 615655, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(908, 5, '1520 Gems', 486331, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(909, 1, '1735 Diamonds', 603594, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(910, 4, '208 Gems', 188294, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(911, 2, '2655 Coins', 509169, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(912, 3, '2530 Gems', 506826, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(913, 2, '4186 UC', 389069, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(914, 3, '685 Coins', 605365, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(915, 4, '1825 Gems', 203665, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(916, 2, '529 Diamonds', 951060, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(917, 1, '3643 Coins', 465787, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(918, 1, '3201 Coins', 881096, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(919, 7, '1766 UC', 497560, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(920, 3, '934 Coins', 178683, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(921, 3, '222 Diamonds', 20702, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(922, 1, '842 Gems', 971036, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(923, 5, '2319 Coins', 655534, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(924, 3, '2340 Coins', 433822, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(926, 4, '1720 Diamonds', 130966, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(927, 2, '2215 Gems', 138485, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(928, 7, '2862 Gems', 63263, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(929, 1, '1515 Diamonds', 186626, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(930, 2, '2442 Coins', 777394, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(931, 3, '4293 Coins', 844323, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(932, 4, '812 Gems', 129986, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(933, 1, '408 Gems', 239569, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(934, 5, '3747 Coins', 181990, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(936, 2, '2871 Diamonds', 111897, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(937, 3, '2008 Gems', 847961, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(938, 4, '2662 Diamonds', 387400, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(939, 7, '4911 Diamonds', 937401, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(940, 5, '702 Gems', 613143, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(941, 4, '4495 Gems', 67858, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(943, 5, '2628 UC', 516798, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(944, 1, '3233 Diamonds', 17200, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(945, 5, '4202 Gems', 553904, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(946, 1, '4868 Diamonds', 137756, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(947, 4, '1492 Diamonds', 292993, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(948, 1, '2841 Diamonds', 368928, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(949, 7, '2763 Gems', 259119, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(950, 2, '1854 Gems', 94701, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(951, 5, '507 UC', 576365, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(952, 2, '4453 Gems', 608660, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(953, 1, '2120 Gems', 644317, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(954, 4, '2785 Coins', 597812, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(955, 2, '284 UC', 111011, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(956, 3, '2364 Coins', 855347, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(957, 5, '2120 UC', 766935, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(958, 2, '4533 Gems', 745035, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(959, 5, '1332 Diamonds', 228148, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(960, 1, '3551 UC', 93908, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(961, 2, '3003 UC', 474671, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(962, 7, '3786 Coins', 634963, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(963, 5, '616 Gems', 319306, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(967, 2, '384 Diamonds', 246089, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(968, 4, '3133 Diamonds', 831893, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(969, 2, '4480 Gems', 414136, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(970, 7, '2230 UC', 987264, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(971, 7, '2727 Diamonds', 250042, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(972, 7, '1480 Gems', 433928, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(973, 1, '412 UC', 292850, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(974, 5, '4777 UC', 552189, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(975, 5, '4436 Coins', 99517, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(976, 1, '2964 UC', 152801, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(977, 4, '3040 UC', 22822, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(978, 4, '447 Coins', 80669, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(979, 2, '1157 Diamonds', 242164, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(981, 7, '966 UC', 193073, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(983, 5, '3070 UC', 785214, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(985, 7, '1827 Diamonds', 241832, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(986, 1, '2278 Diamonds', 596538, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(987, 3, '3610 Gems', 848863, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(988, 3, '662 Coins', 307641, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(989, 3, '3797 Gems', 526298, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(990, 5, '2926 Coins', 577791, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(991, 2, '1697 UC', 319714, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(992, 2, '378 UC', 464311, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(993, 4, '4935 Diamonds', 297264, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(994, 2, '3530 Diamonds', 104636, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(995, 1, '4943 UC', 923420, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(996, 4, '1731 Gems', 599439, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(997, 5, '2863 Coins', 862602, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(998, 3, '966 Gems', 183936, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(999, 5, '979 Coins', 773650, 'items/default.png', '2025-07-28 06:48:17', '2025-07-28 06:48:17');

--
-- Trigger `topup_items`
--
DELIMITER $$
CREATE TRIGGER `trg_before_price_update` BEFORE UPDATE ON `topup_items` FOR EACH ROW BEGIN
    -- OLD mereferensikan nilai baris SEBELUM update
    -- NEW mereferensikan nilai baris SESUDAH update
    IF NEW.price < OLD.price THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Price cannot be decreased.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `transactions`
--

CREATE TABLE `transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `transaction_code` varchar(255) NOT NULL,
  `game_name` varchar(255) NOT NULL,
  `game_user_id` varchar(255) NOT NULL,
  `game_server` varchar(255) DEFAULT NULL,
  `nominal_amount` varchar(255) NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `payment_method` varchar(255) NOT NULL,
  `whatsapp_number` varchar(255) DEFAULT NULL,
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `transactions`
--

INSERT INTO `transactions` (`id`, `user_id`, `transaction_code`, `game_name`, `game_user_id`, `game_server`, `nominal_amount`, `price`, `payment_method`, `whatsapp_number`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'TPN-M40VGPOIHA', 'Valorant', 'Player7857', NULL, '4790 Gems', 45566, 'DANA', '081234567894', 'completed', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(2, 1, 'TPN-JAB3BQCBXL', 'PUBG Mobile', 'Player7090', '4951', '4217 UC', 539971, 'DANA', '081234567899', 'completed', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(3, 1, 'TPN-9BCUPPFVBX', 'PUBG Mobile', 'Player1027', '6302', '1017 Gems', 572165, 'QRIS', '081234567899', 'completed', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(4, 1, 'TPN-JGI8I9NLAI', 'Genshin Impact', 'Player5059', '7948', '1731 Gems', 599439, 'QRIS', '081234567895', 'completed', '2025-07-28 06:48:17', '2025-07-28 06:48:17'),
(5, 1, 'TPN-OCNLY2MSJC', 'Clash of Clans', 'Player1147', NULL, '3528 Diamonds', 166428, 'QRIS', '081234567899', 'completed', '2025-07-27 06:48:17', '2025-07-27 06:48:17'),
(6, 1, 'TPN-TDTPHDLDAV', 'PUBG Mobile', 'Player4777', '3123', '3786 Coins', 634963, 'OVO', '081234567899', 'completed', '2025-07-27 06:48:17', '2025-07-27 06:48:17'),
(7, 1, 'TPN-JCR4W20LSS', 'Clash of Clans', 'Player3755', NULL, '284 UC', 111011, 'OVO', '081234567893', 'completed', '2025-07-27 06:48:17', '2025-07-27 06:48:17'),
(8, 1, 'TPN-X5LOJP2KFN', 'Clash of Clans', 'Player3829', NULL, '1692 Diamonds', 491297, 'QRIS', '081234567899', 'completed', '2025-07-27 06:48:17', '2025-07-27 06:48:17'),
(9, 1, 'TPN-HZFRT1FJIW', 'Roblox', 'Player2642', NULL, '4250 Coins', 99859, 'DANA', '081234567890', 'completed', '2025-07-26 06:48:17', '2025-07-26 06:48:17'),
(10, 1, 'TPN-MQYXJFDZC8', 'PUBG Mobile', 'Player8707', '5865', '2151 Coins', 370667, 'OVO', '081234567895', 'completed', '2025-07-26 06:48:17', '2025-07-26 06:48:17'),
(11, 1, 'TPN-WXA0LQ7CNK', 'Free Fire', 'Player4426', NULL, '1332 Diamonds', 228148, 'DANA', '081234567891', 'completed', '2025-07-25 06:48:17', '2025-07-25 06:48:17'),
(12, 1, 'TPN-NUS9P1USXT', 'Roblox', 'Player4312', NULL, '4330 Coins', 111891, 'DANA', '081234567899', 'completed', '2025-07-25 06:48:17', '2025-07-25 06:48:17'),
(13, 1, 'TPN-IRY9SWTGGP', 'PUBG Mobile', 'Player4500', '5842', '1440 Gems', 141557, 'OVO', '081234567897', 'completed', '2025-07-25 06:48:17', '2025-07-25 06:48:17'),
(14, 1, 'TPN-PBAWU4X1QH', 'PUBG Mobile', 'Player3718', '6247', '188 Coins', 578905, 'QRIS', '081234567894', 'completed', '2025-07-24 06:48:17', '2025-07-24 06:48:17'),
(15, 1, 'TPN-VBXJE32KNS', 'Valorant', 'Player6254', NULL, '2278 Diamonds', 596538, 'QRIS', '081234567899', 'completed', '2025-07-24 06:48:17', '2025-07-24 06:48:17'),
(16, 1, 'TPN-CPRT5AJOWC', 'Free Fire', 'Player2854', NULL, '4563 Coins', 387182, 'QRIS', '081234567897', 'completed', '2025-07-23 06:48:17', '2025-07-23 06:48:17'),
(17, 1, 'TPN-9RJGSCQV5P', 'Mobile Legends', 'Player1347', '6217', '4851 UC', 311687, 'OVO', '081234567899', 'completed', '2025-07-23 06:48:17', '2025-07-23 06:48:17'),
(18, 1, 'TPN-XBRZUB5TFU', 'Clash of Clans', 'Player4731', NULL, '521 UC', 34599, 'DANA', '081234567893', 'completed', '2025-07-22 06:48:17', '2025-07-22 06:48:17'),
(19, 1, 'TPN-I7IEIZBM7Y', 'Roblox', 'Player4619', NULL, '2343 Coins', 223645, 'DANA', '081234567893', 'completed', '2025-07-22 06:48:17', '2025-07-22 06:48:17'),
(20, 1, 'TPN-851BFJJUOK', 'PUBG Mobile', 'Player6171', '1645', '3650 Diamonds', 435225, 'DANA', '081234567896', 'completed', '2025-07-22 06:48:17', '2025-07-22 06:48:17'),
(21, 2, 'TPN-TESTING-001', 'Valorant', 'PlayerTest', NULL, '53 VP', 14500, 'DANA', NULL, 'completed', '2025-07-28 14:18:39', '2025-07-28 14:18:39');

--
-- Trigger `transactions`
--
DELIMITER $$
CREATE TRIGGER `trg_after_transaction_insert` AFTER INSERT ON `transactions` FOR EACH ROW BEGIN
    INSERT INTO audit_log(log_entry) 
    VALUES (CONCAT('New transaction ', NEW.transaction_code, ' for Rp', NEW.price, ' was created.'));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL DEFAULT 'user',
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `role`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Admin', 'admin@topup.in', NULL, '$2y$12$AAxA.BekHYI9GAjtogI8qulafbABQbldPfYhT58Gt0G5bDnWdCpBq', 'admin', NULL, '2025-07-28 06:48:13', '2025-07-28 06:48:13'),
(2, 'Hafid', 'hafid@gmail.com', NULL, '$2y$12$XmnBz43hJPpdHt2dnqlsZOYg1QZGh5dWEf5sfdyHkb4/kNnIta/Ya', 'user', NULL, '2025-07-28 06:48:13', '2025-07-28 06:48:13');

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `valorantitems`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `valorantitems` (
`id` bigint(20) unsigned
,`name` varchar(255)
,`price` int(10) unsigned
,`game_id` bigint(20) unsigned
);

-- --------------------------------------------------------

--
-- Struktur untuk view `cheapvalorantitems`
--
DROP TABLE IF EXISTS `cheapvalorantitems`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `cheapvalorantitems`  AS SELECT `valorantitems`.`id` AS `id`, `valorantitems`.`name` AS `name`, `valorantitems`.`price` AS `price`, `valorantitems`.`game_id` AS `game_id` FROM `valorantitems` WHERE `valorantitems`.`price` < 50000WITH CASCADEDCHECK OPTION  ;

-- --------------------------------------------------------

--
-- Struktur untuk view `danatransactions`
--
DROP TABLE IF EXISTS `danatransactions`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `danatransactions`  AS SELECT `transactions`.`transaction_code` AS `transaction_code`, `transactions`.`game_name` AS `game_name`, `transactions`.`price` AS `price`, `transactions`.`status` AS `status`, `transactions`.`created_at` AS `created_at` FROM `transactions` WHERE `transactions`.`payment_method` = 'DANA' ;

-- --------------------------------------------------------

--
-- Struktur untuk view `gamedisplayinfo`
--
DROP TABLE IF EXISTS `gamedisplayinfo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `gamedisplayinfo`  AS SELECT `games`.`name` AS `name`, `games`.`slug` AS `slug`, `games`.`logo` AS `logo` FROM `games` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `valorantitems`
--
DROP TABLE IF EXISTS `valorantitems`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `valorantitems`  AS SELECT `topup_items`.`id` AS `id`, `topup_items`.`name` AS `name`, `topup_items`.`price` AS `price`, `topup_items`.`game_id` AS `game_id` FROM `topup_items` WHERE `topup_items`.`game_id` = 1 ;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `accounts_game_id_foreign` (`game_id`);

--
-- Indeks untuk tabel `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`);

--
-- Indeks untuk tabel `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`);

--
-- Indeks untuk tabel `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indeks untuk tabel `games`
--
ALTER TABLE `games`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `games_slug_unique` (`slug`);

--
-- Indeks untuk tabel `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indeks untuk tabel `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indeks untuk tabel `ratings`
--
ALTER TABLE `ratings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_game` (`user_id`,`game_id`),
  ADD KEY `game_id` (`game_id`);

--
-- Indeks untuk tabel `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indeks untuk tabel `topup_items`
--
ALTER TABLE `topup_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `topup_items_game_id_foreign` (`game_id`),
  ADD KEY `idx_game_price` (`game_id`,`price`);

--
-- Indeks untuk tabel `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `transactions_transaction_code_unique` (`transaction_code`),
  ADD KEY `transactions_user_id_foreign` (`user_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT untuk tabel `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `games`
--
ALTER TABLE `games`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT untuk tabel `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT untuk tabel `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `topup_items`
--
ALTER TABLE `topup_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1000;

--
-- AUTO_INCREMENT untuk tabel `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `accounts`
--
ALTER TABLE `accounts`
  ADD CONSTRAINT `accounts_game_id_foreign` FOREIGN KEY (`game_id`) REFERENCES `games` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `ratings`
--
ALTER TABLE `ratings`
  ADD CONSTRAINT `ratings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `ratings_ibfk_2` FOREIGN KEY (`game_id`) REFERENCES `games` (`id`);

--
-- Ketidakleluasaan untuk tabel `topup_items`
--
ALTER TABLE `topup_items`
  ADD CONSTRAINT `topup_items_game_id_foreign` FOREIGN KEY (`game_id`) REFERENCES `games` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
