-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 26-03-2025 a las 18:45:03
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `parking`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_hora_salida` (IN `p_registro_id` INT, IN `p_hora_salida` DATETIME)   BEGIN
    UPDATE registro_de_vehiculo 
    SET hora_salida = p_hora_salida 
    WHERE id = p_registro_id;

    UPDATE puesto_de_vehiculo 
    SET ocupado = FALSE 
    WHERE id = (
        SELECT id 
        FROM puesto_de_vehiculo 
        WHERE ocupado = TRUE 
        LIMIT 1
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_vehiculo` (IN `p_hora_llegada` DATETIME, IN `p_placa` VARCHAR(20), IN `p_usuario_id` INT)   BEGIN
    INSERT INTO registro_de_vehiculo (hora_llegada, placa) VALUES (p_hora_llegada, p_placa);
    UPDATE puesto_de_vehiculo SET ocupado = TRUE WHERE ocupado = FALSE LIMIT 1;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_tiempo_estancia` (`p_registro_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE tiempo_estancia INT;
    
    -- Calcular la diferencia en minutos entre la hora de salida y la llegada
    SELECT TIMESTAMPDIFF(MINUTE, hora_llegada, hora_salida) 
    INTO tiempo_estancia
    FROM registro_de_vehiculo 
    WHERE id = p_registro_id;
    
    RETURN IFNULL(tiempo_estancia, 0); -- Si el vehículo aún no ha salido, retorna 0
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `calcular_total_facturado` (`p_placa` VARCHAR(20)) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    
    -- Sumar todos los montos de facturación del vehículo
    SELECT SUM(monto) 
    INTO total
    FROM facturacion 
    WHERE id_registro IN (SELECT id FROM registro_de_vehiculo WHERE placa = p_placa);
    
    RETURN IFNULL(total, 0); -- Si no hay facturas, retorna 0
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `hay_puestos_disponibles` () RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE disponibles INT;
    
    -- Contar la cantidad de puestos que no están ocupados
    SELECT COUNT(*) INTO disponibles 
    FROM puesto_de_vehiculo 
    WHERE ocupado = FALSE;
    
    -- Retornar TRUE (1) si hay puestos disponibles, FALSE (0) si no hay
    RETURN IF(disponibles > 0, TRUE, FALSE);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estado_del_vehiculo`
--

CREATE TABLE `estado_del_vehiculo` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `estado_del_vehiculo`
--

INSERT INTO `estado_del_vehiculo` (`id`, `descripcion`) VALUES
(1, 'Limpio'),
(2, 'Sucio'),
(3, 'En reparacion');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturacion`
--

CREATE TABLE `facturacion` (
  `id` int(11) NOT NULL,
  `id_registro` int(11) NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `facturacion`
--

INSERT INTO `facturacion` (`id`, `id_registro`, `monto`, `fecha`) VALUES
(1, 1, 50.00, '2023-10-01 10:05:00'),
(2, 2, 30.00, '2023-10-01 09:35:00'),
(3, 3, 70.00, '2023-10-01 12:35:00');

--
-- Disparadores `facturacion`
--
DELIMITER $$
CREATE TRIGGER `before_insert_facturacion` BEFORE INSERT ON `facturacion` FOR EACH ROW BEGIN
    DECLARE vehiculo_salida DATETIME;
    
    -- Obtener la hora de salida del vehículo
    SELECT hora_salida INTO vehiculo_salida 
    FROM registro_de_vehiculo 
    WHERE id = NEW.id_registro;
    
    -- Si el vehículo no ha salido, lanzar un error
    IF vehiculo_salida IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede facturar un vehículo que aún no ha salido';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `puesto_de_vehiculo`
--

CREATE TABLE `puesto_de_vehiculo` (
  `id` int(11) NOT NULL,
  `numero_puesto` int(11) NOT NULL,
  `ocupado` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `puesto_de_vehiculo`
--

INSERT INTO `puesto_de_vehiculo` (`id`, `numero_puesto`, `ocupado`) VALUES
(1, 1, 1),
(2, 2, 0),
(3, 3, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `registro_de_vehiculo`
--

CREATE TABLE `registro_de_vehiculo` (
  `id` int(11) NOT NULL,
  `hora_llegada` datetime NOT NULL,
  `hora_salida` datetime DEFAULT NULL,
  `placa` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `registro_de_vehiculo`
--

INSERT INTO `registro_de_vehiculo` (`id`, `hora_llegada`, `hora_salida`, `placa`) VALUES
(1, '2023-10-01 08:00:00', '2023-10-01 10:00:00', 'ABC123'),
(2, '2023-10-01 09:30:00', NULL, 'XYZ789'),
(3, '2023-10-01 11:00:00', '2023-10-01 12:30:00', 'LMN456');

--
-- Disparadores `registro_de_vehiculo`
--
DELIMITER $$
CREATE TRIGGER `after_insert_registro_vehiculo` AFTER INSERT ON `registro_de_vehiculo` FOR EACH ROW BEGIN
    INSERT INTO estado_del_vehiculo (descripcion) VALUES ('Sucio');
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_update_hora_salida` AFTER UPDATE ON `registro_de_vehiculo` FOR EACH ROW BEGIN
    -- Si la hora de salida fue actualizada
    IF NEW.hora_salida IS NOT NULL THEN
        UPDATE puesto_de_vehiculo 
        SET ocupado = FALSE 
        WHERE id = (
            SELECT id FROM puesto_de_vehiculo WHERE ocupado = TRUE LIMIT 1
        );
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `servicio_de_lavado`
--

CREATE TABLE `servicio_de_lavado` (
  `id` int(11) NOT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `servicio_de_lavado`
--

INSERT INTO `servicio_de_lavado` (`id`, `disponible`) VALUES
(1, 1),
(2, 0),
(3, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `telefono` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id`, `nombre`, `correo`, `telefono`) VALUES
(1, 'Juan Perez', 'juan.perez@example.com', '123456789'),
(2, 'Maria Lopez', 'maria.lopez@example.com', '987654321'),
(3, 'Carlos Gomez', 'carlos.gomez@example.com', '456123789');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_facturacion`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_facturacion` (
`factura_id` int(11)
,`monto` decimal(10,2)
,`fecha` datetime
,`vehiculo_placa` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_puestos_disponibles`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_puestos_disponibles` (
`puesto_id` int(11)
,`numero_puesto` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_registro_vehiculos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_registro_vehiculos` (
`registro_id` int(11)
,`hora_llegada` datetime
,`hora_salida` datetime
,`placa` varchar(20)
,`usuario_nombre` varchar(100)
,`usuario_correo` varchar(100)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_facturacion`
--
DROP TABLE IF EXISTS `vista_facturacion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_facturacion`  AS SELECT `f`.`id` AS `factura_id`, `f`.`monto` AS `monto`, `f`.`fecha` AS `fecha`, `rv`.`placa` AS `vehiculo_placa` FROM (`facturacion` `f` join `registro_de_vehiculo` `rv` on(`f`.`id_registro` = `rv`.`id`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_puestos_disponibles`
--
DROP TABLE IF EXISTS `vista_puestos_disponibles`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_puestos_disponibles`  AS SELECT `puesto_de_vehiculo`.`id` AS `puesto_id`, `puesto_de_vehiculo`.`numero_puesto` AS `numero_puesto` FROM `puesto_de_vehiculo` WHERE `puesto_de_vehiculo`.`ocupado` = 0 ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_registro_vehiculos`
--
DROP TABLE IF EXISTS `vista_registro_vehiculos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_registro_vehiculos`  AS SELECT `rv`.`id` AS `registro_id`, `rv`.`hora_llegada` AS `hora_llegada`, `rv`.`hora_salida` AS `hora_salida`, `rv`.`placa` AS `placa`, `u`.`nombre` AS `usuario_nombre`, `u`.`correo` AS `usuario_correo` FROM (`registro_de_vehiculo` `rv` left join `usuario` `u` on(`rv`.`id` = `u`.`id`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `estado_del_vehiculo`
--
ALTER TABLE `estado_del_vehiculo`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_registro` (`id_registro`);

--
-- Indices de la tabla `puesto_de_vehiculo`
--
ALTER TABLE `puesto_de_vehiculo`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `registro_de_vehiculo`
--
ALTER TABLE `registro_de_vehiculo`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `servicio_de_lavado`
--
ALTER TABLE `servicio_de_lavado`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `estado_del_vehiculo`
--
ALTER TABLE `estado_del_vehiculo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `puesto_de_vehiculo`
--
ALTER TABLE `puesto_de_vehiculo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `registro_de_vehiculo`
--
ALTER TABLE `registro_de_vehiculo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `servicio_de_lavado`
--
ALTER TABLE `servicio_de_lavado`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD CONSTRAINT `facturacion_ibfk_1` FOREIGN KEY (`id_registro`) REFERENCES `registro_de_vehiculo` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
