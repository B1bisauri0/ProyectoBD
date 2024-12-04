
/* 
Para cada upsert, si se va a utilizar como update hay que hacer un get
primero para obtener todos los datos originales (porque el upsert no 
acepta campos null) y si hay que modificar unos, se hace.
*/


-----------------------------------------
-------- UPSERTS Store Procedures -------
-----------------------------------------

-- Valida formato de correo
CREATE PROCEDURE sp_validateEmailFormat
    @Correo_Electronico NVARCHAR(150),
    @OutCode INT OUTPUT
AS
BEGIN
    IF PATINDEX('%_@__%.__%', @Correo_Electronico) = 0
        SET @OutCode = 50003;  -- Correo inválido
    ELSE
        SET @OutCode = 0;  -- Éxito
END;
GO

-- valida si el email es unico
CREATE PROCEDURE sp_checkUniqueEmail
    @Correo_Electronico NVARCHAR(150),
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico)
        SET @OutCode = 50001;  -- Correo ya existe
    ELSE
        SET @OutCode = 0;  -- Éxito
END;
GO

-- Encuentra el Id del usuario mediante el correo
CREATE FUNCTION fn_GetUserId (@Correo_Electronico NVARCHAR(150))
RETURNS INT
AS
BEGIN
    RETURN (SELECT ID_Usuario FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico);
END;
GO

-- Valida si ya existe una direccion principal
CREATE PROCEDURE sp_checkPrincipalAddress
    @Usuario_Id INT,
    @dir_id INT = NULL,
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Direcciones 
               WHERE ID_Usuario = @Usuario_Id 
                 AND Principal = 1 
                 AND (@dir_id IS NULL OR ID_Direccion <> @dir_id))
    BEGIN
        SET @OutCode = 50006; -- Dirección principal ya existe
    END
    ELSE
    BEGIN
        SET @OutCode = 0; -- No hay conflicto
    END
END;
GO


-- Verifica si ya existe un metodo principal de pago
CREATE PROCEDURE sp_checkPrincipalMetodo
    @Usuario_Id INT,
    @metodo_id INT = NULL,
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Métodos_Pago 
               WHERE ID_Usuario = @Usuario_Id 
                 AND Principal = 1 
                 AND (@metodo_id IS NULL OR ID_Metodo_Pago <> @metodo_id))
    BEGIN
        SET @OutCode = 50007; -- Método principal ya existe
    END
    ELSE
    BEGIN
        SET @OutCode = 0; -- No hay conflicto
    END
END;
GO


-- Verifica que no hayan mas de tres metodos de pago
CREATE PROCEDURE sp_checkMaxMetodosPago
    @Usuario_Id INT,
    @OutCode INT OUTPUT
AS
BEGIN
    IF (SELECT COUNT(*) FROM Métodos_Pago WHERE ID_Usuario = @Usuario_Id) >= 3
    BEGIN
        SET @OutCode = 50022; -- Usuario ya tiene tres métodos de pago
    END
    ELSE
    BEGIN
        SET @OutCode = 0; -- Dentro del límite permitido
    END
END;
GO


-- Obetener ID de categoria con el nombre
CREATE FUNCTION fn_GetCategoryId (@nombre_categoria NVARCHAR(100))
RETURNS INT
AS
BEGIN
    RETURN (SELECT ID_Categoria 
            FROM Categorías 
            WHERE LOWER(TRIM(Nombre_Categoria)) = LOWER(TRIM(@nombre_categoria)));
END;
GO


-- Obtener ID de marca con el nombre
CREATE FUNCTION fn_GetBrandId (@nombre_marca NVARCHAR(100))
RETURNS INT
AS
BEGIN
    RETURN (SELECT ID_Marca 
            FROM Marcas 
            WHERE LOWER(TRIM(Nombre_Marca)) = LOWER(TRIM(@nombre_marca)));
END;
GO



	--------------------------
	-------- Usuarios --------
	--------------------------

CREATE PROCEDURE sp_insertUsuario
    @Nombre NVARCHAR(100),
    @Apellido NVARCHAR(100),
    @Correo_Electronico NVARCHAR(150),
    @Contraseña NVARCHAR(255),
    @Teléfono NVARCHAR(20),
    @Tipo_Usuario NVARCHAR(50),
    @OutCode INT OUTPUT
AS
BEGIN
    INSERT INTO Usuarios (Nombre, Apellido, Correo_Electronico, Contraseña, Teléfono, 
                          Tipo_Usuario, Fecha_Registro)
    VALUES (TRIM(@Nombre), TRIM(@Apellido), LOWER(TRIM(@Correo_Electronico)), 
            @Contraseña, @Teléfono, LOWER(TRIM(@Tipo_Usuario)), GETDATE());
    SET @OutCode = 0;  -- Éxito
END;
GO

CREATE PROCEDURE sp_updateUsuario
    @Nombre NVARCHAR(100),
    @Apellido NVARCHAR(100),
    @Correo_Electronico NVARCHAR(150),
    @Contraseña NVARCHAR(255),
    @Teléfono NVARCHAR(20),
    @Tipo_Usuario NVARCHAR(50),
    @OutCode INT OUTPUT
AS
BEGIN
    UPDATE Usuarios
    SET Nombre = TRIM(@Nombre),
        Apellido = TRIM(@Apellido),
        Contraseña = @Contraseña,
        Teléfono = @Teléfono,
        Tipo_Usuario = LOWER(TRIM(@Tipo_Usuario))
    WHERE Correo_Electronico = @Correo_Electronico;

    SET @OutCode = 0;  -- Éxito
END;
GO

CREATE PROCEDURE upsert_usuario
    @Nombre NVARCHAR(100),
    @Apellido NVARCHAR(100),
    @Correo_Electronico NVARCHAR(150),
    @Contraseña NVARCHAR(255),
    @Teléfono NVARCHAR(20) = NULL,
    @Tipo_Usuario NVARCHAR(50),
    @OutCode INT OUTPUT  
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- CTE para validaciones
        WITH Validaciones AS (
            SELECT
                CASE 
                    WHEN @Nombre IS NULL OR LEN(@Nombre) > 100 THEN 1
                    WHEN @Apellido IS NULL OR LEN(@Apellido) > 100 THEN 1
                    WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
                    WHEN @Contraseña IS NULL OR LEN(@Contraseña) > 255 THEN 1
                    WHEN LEN(@Teléfono) > 20 THEN 1
                    WHEN @Tipo_Usuario IS NULL OR LEN(@Tipo_Usuario) > 50 THEN 1
                    ELSE 0
                END AS ParamInvalido
        )
        SELECT @OutCode = 50017 FROM Validaciones WHERE ParamInvalido = 1;

        IF @OutCode = 50017
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validar tipo de usuario
        IF LOWER(@Tipo_Usuario) NOT IN ('cliente', 'administrador')
        BEGIN
            SET @OutCode = 50002;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validar formato de correo
        EXEC sp_validateEmailFormat @Correo_Electronico, @OutCode OUTPUT;
        IF @OutCode <> 0
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si el usuario existe
        DECLARE @Usuario_Existe BIT = (SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END 
                                       FROM Usuarios 
                                       WHERE Correo_Electronico = @Correo_Electronico);

        IF @Usuario_Existe = 0
        BEGIN
            -- Validar correo único
            EXEC sp_checkUniqueEmail @Correo_Electronico, @OutCode OUTPUT;
            IF @OutCode <> 0
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Insertar nuevo usuario
            EXEC sp_insertUsuario 
                @Nombre, @Apellido, @Correo_Electronico, @Contraseña, 
                @Teléfono, @Tipo_Usuario, @OutCode OUTPUT;
        END
        ELSE
        BEGIN
            -- Actualizar usuario existente
            EXEC sp_updateUsuario 
                @Nombre, @Apellido, @Correo_Electronico, @Contraseña, 
                @Teléfono, @Tipo_Usuario, @OutCode OUTPUT;
        END

        -- Confirmar la transacción si no hubo errores
        IF @OutCode = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @OutCode = ERROR_NUMBER();
        THROW;
    END CATCH
END;
GO


-- CREATE PROCEDURE upsert_usuario
--     @Nombre NVARCHAR(100),
--     @Apellido NVARCHAR(100),
--     @Correo_Electronico NVARCHAR(150),
--     @Contraseña NVARCHAR(255),
--     @Teléfono NVARCHAR(20) = NULL,
--     @Tipo_Usuario NVARCHAR(50),
--     @OutCode INT OUTPUT  
-- AS
-- BEGIN
--     -- Iniciar una transacción
--     BEGIN TRANSACTION;

--     BEGIN TRY
-- 		-- Verificar datos
-- 		DECLARE @InvalidParam BIT = 0;
--         -- Validación de campos requeridos y sus restricciones
--         SET @InvalidParam = CASE 
--             WHEN @Nombre IS NULL OR LEN(@nombre) > 100 THEN 1
--             WHEN @Apellido IS NULL OR LEN(@nombre) > 100 THEN 1
--             WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
--             WHEN @Contraseña IS NULL OR LEN(@Contraseña) > 255 THEN 1
--             WHEN LEN(@Teléfono) > 20 THEN 1
--             WHEN @Tipo_Usuario IS NULL OR LEN(@Tipo_Usuario) > 50 THEN 1
--             ELSE 0
--         END;
-- 		-- Verificar si hay algún parámetro inválido
--         IF @InvalidParam = 1
--         BEGIN
--             SET @OutCode = 50017;  -- Código genérico de error en parámetros
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

--         DECLARE @Usuario_Existe INT;
--         -- Validar que el tipo de usuario sea 'cliente' o 'administrador'
--         IF LOWER(@Tipo_Usuario) NOT IN ('cliente', 'administrador')
--         BEGIN
--             SET @OutCode = 50002;  -- Tipo de usuario no existe
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

--         -- Validar que el correo tenga una estructura válida
--         IF PATINDEX('%_@__%.__%', @Correo_Electronico) = 0
--         BEGIN
--             SET @OutCode = 50003;  -- Formato de correo electrónico no valido
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

--         -- Comprobar si el usuario existe mediante el correo electrónico
--         SET @Usuario_Existe = (SELECT COUNT(*) FROM Usuarios 
-- 		WHERE Correo_Electronico = @Correo_Electronico);

--         IF @Usuario_Existe = 0
--         BEGIN
--             -- Validar que el correo electrónico es único solo en caso de inserción
--             IF EXISTS (SELECT 1 FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico)
--             BEGIN
--                 SET @OutCode = 50001;  -- Correo electrónico ya existe
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
            
--             -- Insertar un nuevo registro si el usuario no existe
--             INSERT INTO Usuarios (Nombre, Apellido, Correo_Electronico, Contraseña, Teléfono, 
-- 									Tipo_Usuario, Fecha_Registro)
--             VALUES (TRIM(@Nombre), TRIM(@Apellido), LOWER(TRIM(@Correo_Electronico)), 
--                     @Contraseña, @Teléfono, LOWER(TRIM(@Tipo_Usuario)), GETDATE());

--             SET @OutCode = 0;  -- Código 0 indica éxito en inserción
--         END
--         ELSE
--         BEGIN
--             -- Actualizar el registro si el usuario ya existe
--             UPDATE Usuarios
--             SET Nombre = TRIM(@Nombre),
--                 Apellido = TRIM(@Apellido),
--                 Contraseña = @Contraseña,
--                 Teléfono = @Teléfono,
--                 Tipo_Usuario = LOWER(TRIM(@Tipo_Usuario))
--             WHERE Correo_Electronico = @Correo_Electronico;

--             SET @OutCode = 0;  -- Código 0 indica éxito en actualización
--         END

--         -- Confirmar la transacción si no hay errores
--         COMMIT TRANSACTION;

--     END TRY
--     BEGIN CATCH
--         -- Hacer ROLLBACK en caso de error
--         IF @@TRANCOUNT > 0
--             ROLLBACK TRANSACTION;

--         -- Capturar y mostrar el mensaje de error
--         DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

--         -- Asignar código de error general para cualquier otra falla
--         SET @OutCode = 3;

--         -- Lanzar el error capturado
--         THROW 50000, @ErrorMessage, 1;
--     END CATCH
-- END;
-- GO



DECLARE @OutCode INT;
EXEC upsert_usuario
    @Nombre = N'Alonso',
    @Apellido = N'Durán',
    @Correo_Electronico = N'alduran@estudianteC.com        ',
    @Contraseña = N'1234',
    @Teléfono = N'88888888',
    @Tipo_Usuario = N'cliente',
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;





	-----------------------------
	-------- Direcciones -------- -- Varias direcciones por usuario
	-----------------------------

CREATE PROCEDURE sp_insertDireccion
    @Usuario_Id INT,
    @direccion NVARCHAR(255),
    @ciudad NVARCHAR(100),
    @provincia NVARCHAR(100),
    @codigo_postal NVARCHAR(20),
    @pais NVARCHAR(50),
    @principal BIT,
    @OutCode INT OUTPUT
AS
BEGIN
    INSERT INTO Direcciones (ID_Usuario, Direccion, Ciudad, Provincia, Codigo_Postal, Pais, Principal)
    VALUES (@Usuario_Id, LOWER(TRIM(@direccion)), LOWER(TRIM(@ciudad)), 
            LOWER(TRIM(@provincia)), LOWER(TRIM(@codigo_postal)), 
            LOWER(TRIM(@pais)), @principal);
    SET @OutCode = 0; -- Inserción exitosa
END;
GO


CREATE PROCEDURE sp_updateDireccion
    @dir_id INT,
    @Usuario_Id INT,
    @direccion NVARCHAR(255),
    @ciudad NVARCHAR(100),
    @provincia NVARCHAR(100),
    @codigo_postal NVARCHAR(20),
    @pais NVARCHAR(50),
    @principal BIT,
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Direcciones WHERE ID_Direccion = @dir_id AND ID_Usuario = @Usuario_Id)
    BEGIN
        UPDATE Direcciones
        SET Direccion = LOWER(TRIM(@direccion)),
            Ciudad = LOWER(TRIM(@ciudad)),
            Provincia = LOWER(TRIM(@provincia)),
            Codigo_Postal = LOWER(TRIM(@codigo_postal)),
            Pais = LOWER(TRIM(@pais)),
            Principal = @principal
        WHERE ID_Direccion = @dir_id AND ID_Usuario = @Usuario_Id;

        SET @OutCode = 0; -- Actualización exitosa
    END
    ELSE
    BEGIN
        SET @OutCode = 50005; -- Dirección no encontrada
    END
END;
GO


CREATE PROCEDURE upsert_dir
    @Correo_Electronico NVARCHAR(150), -- Con esto, se obtiene el id del usuario
    @dir_id INT = NULL,  -- ID de la dirección, opcional para actualizar
    @direccion NVARCHAR(255),
    @ciudad NVARCHAR(100),
    @provincia NVARCHAR(100),
    @codigo_postal NVARCHAR(20),
    @pais NVARCHAR(50),
    @principal BIT,
    @OutCode INT OUTPUT  
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validaciones con un CTE
        WITH Validaciones AS (
            SELECT
                CASE 
                    WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
                    WHEN @direccion IS NULL OR LEN(@direccion) > 255 THEN 1
                    WHEN @ciudad IS NULL OR LEN(@ciudad) > 100 THEN 1
                    WHEN @provincia IS NULL OR LEN(@provincia) > 100 THEN 1
                    WHEN @codigo_postal IS NULL OR LEN(@codigo_postal) > 20 THEN 1
                    WHEN @pais IS NULL OR LEN(@pais) > 50 THEN 1
                    WHEN @principal IS NULL THEN 1
                    ELSE 0
                END AS ParamInvalido
        )
        SELECT @OutCode = 50017 FROM Validaciones WHERE ParamInvalido = 1;

        IF @OutCode = 50017
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener el ID del usuario
        DECLARE @Usuario_Id INT;
        SET @Usuario_Id = dbo.fn_GetUserId(@Correo_Electronico);

        IF @Usuario_Id IS NULL
        BEGIN
            SET @OutCode = 50004; -- Usuario no existe
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si ya existe una dirección principal
        IF @principal = 1
        BEGIN
            EXEC sp_checkPrincipalAddress @Usuario_Id, @dir_id, @OutCode OUTPUT;
            IF @OutCode <> 0
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Decidir entre inserción o actualización
        IF @dir_id IS NULL
        BEGIN
            -- Insertar nueva dirección
            EXEC sp_insertDireccion 
                @Usuario_Id, @direccion, @ciudad, @provincia, 
                @codigo_postal, @pais, @principal, @OutCode OUTPUT;
        END
        ELSE
        BEGIN
            -- Actualizar dirección existente
            EXEC sp_updateDireccion 
                @dir_id, @Usuario_Id, @direccion, @ciudad, @provincia, 
                @codigo_postal, @pais, @principal, @OutCode OUTPUT;
        END

        -- Confirmar transacción si no hay errores
        IF @OutCode = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- CREATE PROCEDURE upsert_dir
--     @Correo_Electronico NVARCHAR(150), -- Con esto, se obtiene el id del usuario
-- 	@dir_id INT = NULL,  -- ID de la dirección, opcional para actualizar
-- 	@direccion NVARCHAR(255),
-- 	@ciudad NVARCHAR(100),
-- 	@provincia NVARCHAR(100),
-- 	@codigo_postal NVARCHAR(20),
-- 	@pais NVARCHAR(50),
-- 	@principal BIT,
--     @OutCode INT OUTPUT  
-- AS
-- BEGIN
--     Iniciar una transacción
--     BEGIN TRANSACTION;

-- 	TRY-CATCH
--     BEGIN TRY
-- 		Verificar datos
-- 		DECLARE @InvalidParam BIT = 0;
--         Validación de campos requeridos y sus restricciones
--         SET @InvalidParam = CASE 
--             WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
--             WHEN @direccion IS NULL OR LEN(@direccion) > 255 THEN 1
--             WHEN @ciudad IS NULL OR LEN(@ciudad) > 100 THEN 1
--             WHEN @provincia IS NULL OR LEN(@provincia) > 100 THEN 1
--             WHEN @codigo_postal IS NULL OR LEN(@codigo_postal) > 20 THEN 1
--             WHEN @pais IS NULL OR LEN(@pais) > 50 THEN 1
--             WHEN @principal IS NULL THEN 1
--             ELSE 0
--         END;
-- 		Verificar si hay algún parámetro inválido
--         IF @InvalidParam = 1
--         BEGIN
--             SET @OutCode = 50017;  -- Código genérico de error en parámetros
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

-- 		DECLARE @Usuario_Existe INT;
-- 		DECLARE @Usuario_Id INT;

--         Comprobar si el usuario existe mediante el correo electrónico
--         SET @Usuario_Existe = (SELECT COUNT(*) FROM Usuarios 
-- 		WHERE Correo_Electronico = @Correo_Electronico);

--         IF @Usuario_Existe = 0 -- Usuario no existe
--         BEGIN
--             SET @OutCode = 50004; 
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END
-- 		ELSE -- Usuario existe
-- 		BEGIN
-- 			SET @Usuario_Id = (SELECT ID_Usuario FROM Usuarios
-- 							WHERE Correo_Electronico = @Correo_Electronico);
-- 		END

--         Verificar si el usuario ya tiene una dirección principal
--         IF @principal = 1 
--         BEGIN
--             IF EXISTS (SELECT 1 FROM Direcciones 
--                        WHERE ID_Usuario = @Usuario_Id AND Principal = 1 
--                              AND (@dir_id IS NULL OR ID_Direccion <> @dir_id))
--             BEGIN
--                 SET @OutCode = 50006; -- Dirección principal ya existe en este usuario
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
--         END
--         Verificar si se debe hacer un INSERT o un UPDATE
--         IF @dir_id IS NULL -- Realizar un INSERT
--         BEGIN
--             INSERT INTO Direcciones (ID_Usuario, Direccion, Ciudad, Provincia, Codigo_Postal, Pais, Principal)
--             VALUES (@Usuario_Id, LOWER(TRIM(@direccion)), LOWER(TRIM(@ciudad)), 
--                     LOWER(TRIM(@provincia)), LOWER(TRIM(@codigo_postal)), 
--                     LOWER(TRIM(@pais)), @principal);
--             SET @OutCode = 0;  -- Éxito en inserción
--         END
--         ELSE -- Realizar un UPDATE si la dirección existe
--         BEGIN
--             IF EXISTS (SELECT 1 FROM Direcciones WHERE ID_Direccion = @dir_id AND ID_Usuario = @Usuario_Id)
--             BEGIN
--                 UPDATE Direcciones
--                 SET Direccion = LOWER(TRIM(@direccion)),
--                     Ciudad = LOWER(TRIM(@ciudad)),
--                     Provincia = LOWER(TRIM(@provincia)),
--                     Codigo_Postal = LOWER(TRIM(@codigo_postal)),
--                     Pais = LOWER(TRIM(@pais)),
--                     Principal = @principal
--                 WHERE ID_Direccion = @dir_id AND ID_Usuario = @Usuario_Id;
--                 SET @OutCode = 0;  -- Éxito en actualización
--             END
--             ELSE -- Si el ID de dirección no existe o no pertenece al usuario
--             BEGIN
--                 SET @OutCode = 50005; -- Dirección no encontrada
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
--         END

--         Confirmar la transacción si no hay errores
--         COMMIT TRANSACTION;

--     END TRY
--     BEGIN CATCH
--         Hacer ROLLBACK en caso de error
--         IF @@TRANCOUNT > 0
--             ROLLBACK TRANSACTION;

--         Capturar y mostrar el mensaje de error
--         DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

--         Lanzar el error capturado
--         THROW 50000, @ErrorMessage, 1;
--     END CATCH
-- END;
-- GO



DECLARE @OutCode INT;
EXEC upsert_dir
    @Correo_Electronico = 'alduran@estudiantec.com', -- Con esto, se obtiene el id del usuario
	@dir_id = null,  -- ID de la dirección, opcional para actualizar
	@direccion = 'Res Lela 300 m',
	@ciudad = 'Curridabat',
	@provincia = 'San Jose',
	@codigo_postal = '1111',
	@pais = 'Costa Rica',
	@principal = 1,
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	------------------------------
	-------- Métodos_Pago -------- -- Varias por usuario (Maximo 3)
	------------------------------

CREATE PROCEDURE sp_insertMetodoPago
    @Usuario_Id INT,
    @tipo NVARCHAR(50),
    @detalles NVARCHAR(255),
    @principal BIT,
    @OutCode INT OUTPUT
AS
BEGIN
    INSERT INTO Métodos_Pago (ID_Usuario, Tipo, Detalles, Principal)
    VALUES (@Usuario_Id, LOWER(TRIM(@tipo)), LOWER(TRIM(@detalles)), @principal);
    SET @OutCode = 0; -- Inserción exitosa
END;
GO

CREATE PROCEDURE sp_updateMetodoPago
    @metodo_id INT,
    @Usuario_Id INT,
    @tipo NVARCHAR(50),
    @detalles NVARCHAR(255),
    @principal BIT,
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Métodos_Pago WHERE ID_Metodo_Pago = @metodo_id AND ID_Usuario = @Usuario_Id)
    BEGIN
        UPDATE Métodos_Pago
        SET Tipo = LOWER(TRIM(@tipo)),
            Detalles = LOWER(TRIM(@detalles)),
            Principal = @principal
        WHERE ID_Metodo_Pago = @metodo_id AND ID_Usuario = @Usuario_Id;

        SET @OutCode = 0; -- Actualización exitosa
    END
    ELSE
    BEGIN
        SET @OutCode = 50008; -- Método de pago no encontrado
    END
END;
GO

CREATE PROCEDURE upsert_Metodo_Pago
    @Correo_Electronico NVARCHAR(150), -- Con esto, se obtiene el ID del usuario
    @metodo_id INT = NULL,  -- ID del método, opcional para actualizar
    @tipo NVARCHAR(50),
    @detalles NVARCHAR(255),
    @principal BIT,
    @OutCode INT OUTPUT  
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validaciones iniciales con un CTE
        WITH Validaciones AS (
            SELECT
                CASE 
                    WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
                    WHEN @tipo IS NULL OR LEN(@tipo) > 50 THEN 1
                    WHEN @detalles IS NULL OR LEN(@detalles) > 255 THEN 1
                    WHEN @principal IS NULL THEN 1
                    ELSE 0
                END AS ParamInvalido
        )
        SELECT @OutCode = 50017 FROM Validaciones WHERE ParamInvalido = 1;

        IF @OutCode = 50017
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener el ID del usuario
        DECLARE @Usuario_Id INT;
        SET @Usuario_Id = dbo.fn_GetUserId(@Correo_Electronico);

        IF @Usuario_Id IS NULL
        BEGIN
            SET @OutCode = 50004; -- Usuario no existe
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si ya existe un método de pago principal
        IF @principal = 1
        BEGIN
            EXEC sp_checkPrincipalMetodo @Usuario_Id, @metodo_id, @OutCode OUTPUT;
            IF @OutCode <> 0
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Validar que el usuario no tenga más de tres métodos de pago
        IF @metodo_id IS NULL -- Solo validar al insertar
        BEGIN
            EXEC sp_checkMaxMetodosPago @Usuario_Id, @OutCode OUTPUT;
            IF @OutCode <> 0
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Decidir entre inserción o actualización
        IF @metodo_id IS NULL
        BEGIN
            -- Insertar nuevo método de pago
            EXEC sp_insertMetodoPago 
                @Usuario_Id, @tipo, @detalles, @principal, @OutCode OUTPUT;
        END
        ELSE
        BEGIN
            -- Actualizar método de pago existente
            EXEC sp_updateMetodoPago 
                @metodo_id, @Usuario_Id, @tipo, @detalles, @principal, @OutCode OUTPUT;
        END

        -- Confirmar la transacción si no hubo errores
        IF @OutCode = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- CREATE PROCEDURE upsert_Metodo_Pago
--     @Correo_Electronico NVARCHAR(150), -- Con esto, se obtiene el id del usuario
-- 	@metodo_id INT = NULL,  -- ID del metodo, opcional para actualizar
-- 	@tipo NVARCHAR(50),
-- 	@detalles NVARCHAR(255),
-- 	@principal BIT,
--     @OutCode INT OUTPUT  
-- AS
-- BEGIN
--     -- Iniciar una transacción
--     BEGIN TRANSACTION;

-- 	-- TRY-CATCH
--     BEGIN TRY
-- 		DECLARE @InvalidParam BIT = 0;
--         SET @InvalidParam = CASE 
--             WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
--             WHEN @tipo IS NULL OR LEN(@tipo) > 50 THEN 1
--             WHEN @detalles IS NULL OR LEN(@detalles) > 255 THEN 1
--             WHEN @principal IS NULL THEN 1
--             ELSE 0
--         END;
-- 		-- Verificar si hay algún parámetro inválido
--         IF @InvalidParam = 1
--         BEGIN
--             SET @OutCode = 50017;  -- Código genérico de error en parámetros
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

-- 		DECLARE @Usuario_Existe INT;
-- 		DECLARE @Usuario_Id INT;

--         -- Comprobar si el usuario existe mediante el correo electrónico
--         SET @Usuario_Existe = (SELECT COUNT(*) FROM Usuarios 
-- 		WHERE Correo_Electronico = @Correo_Electronico);

--         IF @Usuario_Existe = 0 -- Usuario no existe
--         BEGIN
--             SET @OutCode = 50004; 
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END
-- 		ELSE -- Usuario existe
-- 		BEGIN
-- 			SET @Usuario_Id = (SELECT ID_Usuario FROM Usuarios
-- 							WHERE Correo_Electronico = @Correo_Electronico);
-- 		END

--         -- Verificar si el usuario ya tiene un metodo principal
--         IF @principal = 1 
--         BEGIN
--             IF EXISTS (SELECT 1 FROM Métodos_Pago 
--                        WHERE ID_Usuario = @Usuario_Id AND Principal = 1 
--                              AND (@metodo_id IS NULL OR ID_Metodo_Pago <> @metodo_id))
--             BEGIN
--                 SET @OutCode = 50007; -- Metodo principal ya existe en este usuario
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
--         END
--         -- Verificar si se debe hacer un INSERT o un UPDATE
--         IF @metodo_id IS NULL -- Realizar un INSERT
--         BEGIN
--             INSERT INTO Métodos_Pago(ID_Usuario, Tipo, Detalles, Principal)
--             VALUES (@Usuario_Id, LOWER(TRIM(@tipo)), LOWER(TRIM(@detalles)), @principal);
--             SET @OutCode = 0;  -- Éxito en inserción
--         END
--         ELSE -- Realizar un UPDATE el metodo existe
--         BEGIN
--             IF EXISTS (SELECT 1 FROM Métodos_Pago WHERE ID_Metodo_Pago = @metodo_id AND ID_Usuario = @Usuario_Id)
--             BEGIN
--                 UPDATE Métodos_Pago
--                 SET Tipo = LOWER(TRIM(@tipo)),
--                     Detalles = LOWER(TRIM(@detalles)),
--                     Principal = @principal
--                 WHERE ID_Metodo_Pago = @metodo_id AND ID_Usuario = @Usuario_Id;
--                 SET @OutCode = 0;  -- Éxito en actualización
--             END
--             ELSE -- Si el ID de Metodo de pago no existe o no pertenece al usuario
--             BEGIN
--                 SET @OutCode = 50008; -- Metodo de pago no encontrado
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
--         END

--         -- Confirmar la transacción si no hay errores
--         COMMIT TRANSACTION;

--     END TRY
--     BEGIN CATCH
--         -- Hacer ROLLBACK en caso de error
--         IF @@TRANCOUNT > 0
--             ROLLBACK TRANSACTION;

--         -- Capturar y mostrar el mensaje de error
--         DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

--         -- Lanzar el error capturado
--         THROW 50000, @ErrorMessage, 1;
--     END CATCH
-- END;
-- GO



DECLARE @OutCode INT;
EXEC upsert_Metodo_Pago
    @Correo_Electronico = 'alduran@estudiantec.com', -- Con esto, se obtiene el id del usuario
	@metodo_id = 2,  -- ID de la dirección, opcional para actualizar
	@tipo = 'Debito',
	@detalles = 'Aqui va el detalle mod',
	@principal = 1,
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	--------------------------
	------- Categorías ------- -- Nombre unico
	--------------------------

CREATE PROCEDURE upsert_Categoria
    @nombre NVARCHAR(100),
	@categoria_id INT = NULL,
	@descripcion TEXT,  
    @OutCode INT OUTPUT  
AS
BEGIN
    -- Iniciar una transacción
    BEGIN TRANSACTION;

	-- TRY-CATCH
    BEGIN TRY

		DECLARE @InvalidParam BIT = 0;
        -- Validación de los parámetros requeridos y sus restricciones
        SET @InvalidParam = CASE 
            WHEN @nombre IS NULL OR LEN(@nombre) > 100 THEN 1
            WHEN @descripcion IS NULL THEN 1
            ELSE 0
        END;
        -- Verificar si hay algún parámetro inválido
        IF @InvalidParam = 1
        BEGIN
            SET @OutCode = 50017;  -- Código de error específico para parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END


		DECLARE @name NVARCHAR(100);
		SET @name = LOWER(TRIM(@nombre));

        -- Verificar si se debe hacer un INSERT o un UPDATE
        IF @categoria_id IS NULL -- Realizar un INSERT
        BEGIN
			-- Verificar si el nombre de la categoría ya existe
			IF EXISTS (SELECT 1 FROM Categorías WHERE LOWER(TRIM(Nombre_Categoria)) = @name)
			BEGIN
				SET @OutCode = 50009;  -- Nombre de categoría ya existente
				ROLLBACK TRANSACTION;
				RETURN;
			END
			INSERT INTO Categorías (Nombre_Categoria, Descripcion)
			VALUES (@name, @descripcion);
			SET @OutCode = 0;  -- Éxito en la inserción
        END
        ELSE -- Realizar un UPDATE la categoria existe
        BEGIN
            IF EXISTS (SELECT 1 FROM Categorías WHERE ID_Categoria = @categoria_id)
            BEGIN
                UPDATE Categorías
                SET Nombre_Categoria = @name,
                    Descripcion = @descripcion
                WHERE ID_Categoria = @categoria_id;
                SET @OutCode = 0;  -- Éxito en actualización
            END
            ELSE -- Si el ID de Categoria no existe o no pertenece al usuario
            BEGIN
                SET @OutCode = 50010; -- Categoria no encontrada
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END


        -- Confirmar la transacción si no hay errores
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Hacer ROLLBACK en caso de error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capturar y mostrar el mensaje de error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        -- Lanzar el error capturado
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



DECLARE @OutCode INT;
EXEC upsert_Categoria
    @nombre = 'Laptop        ', 
	@categoria_id = 1,
	@descripcion = 'Computadora portatiles', 
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	----------------------
	------- Marcas ------- --nombre unico
	----------------------

CREATE PROCEDURE upsert_Marca
	@id_marca INT,
    @nombre NVARCHAR(100),
	@descripcion TEXT,  
    @OutCode INT OUTPUT   
AS
BEGIN
    -- Iniciar una transacción
    BEGIN TRANSACTION;

	-- TRY-CATCH
    BEGIN TRY

		DECLARE @InvalidParam BIT = 0;
        -- Validación de los parámetros requeridos y sus restricciones
        SET @InvalidParam = CASE 
            WHEN @nombre IS NULL OR LEN(@nombre) > 100 THEN 1
            WHEN @descripcion IS NULL THEN 1
            ELSE 0
        END;
        -- Verificar si hay algún parámetro inválido
        IF @InvalidParam = 1
        BEGIN
            SET @OutCode = 50017;  -- Código de error específico para parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END


        -- Verificar si se debe hacer un INSERT o un UPDATE
		DECLARE @name NVARCHAR(100);
		SET @name = LOWER(TRIM(@nombre));
        IF @id_marca IS NULL -- Realizar un INSERT
        BEGIN
			-- Verificar si el nombre de la marca ya existe
			IF EXISTS (SELECT 1 FROM Marcas WHERE LOWER(TRIM(Nombre_Marca)) = @name)
			BEGIN
				SET @OutCode = 50011;  -- Nombre de marca ya existente
				ROLLBACK TRANSACTION;
				RETURN;
			END
			-- Insertar la nueva marca si no existe
			INSERT INTO Marcas (Nombre_Marca, Descripcion)
			VALUES (@name, @descripcion);
			SET @OutCode = 0;  -- Éxito en la inserción
        END
        ELSE -- Realizar un UPDATE la categoria existe
        BEGIN
            IF EXISTS (SELECT 1 FROM Marcas WHERE ID_Marca = @id_marca)
            BEGIN
                UPDATE Marcas
                SET Nombre_Marca = @name,
                    Descripcion = @descripcion
                WHERE ID_Marca = @id_marca;
                SET @OutCode = 0;  -- Éxito en actualización
            END
            ELSE -- Si el ID de Categoria no existe o no pertenece al usuario
            BEGIN
                SET @OutCode = 50010; -- Marca no encontrada
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END


        -- Confirmar la transacción si no hay errores
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Hacer ROLLBACK en caso de error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capturar y mostrar el mensaje de error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        -- Lanzar el error capturado
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



DECLARE @OutCode INT;
EXEC upsert_Marca
	@id_marca = null,
    @nombre = 'SnapDragon', 
	@descripcion = 'Microprocesadores', 
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	-------------------------
	------- Productos ------- --nombre no unico
	-------------------------

CREATE PROCEDURE sp_insertProducto
    @nombre NVARCHAR(100),
    @descripcion TEXT,
    @cat_id INT,
    @marca_id INT,
    @precio DECIMAL(10, 2),
    @Existencias INT,
    @imagen VARBINARY(MAX),
    @OutCode INT OUTPUT
AS
BEGIN
    -- Verificar si el nombre del producto ya existe
    IF EXISTS (SELECT 1 FROM Productos WHERE LOWER(TRIM(Nombre_Producto)) = LOWER(TRIM(@nombre)))
    BEGIN
        SET @OutCode = 50013; -- Nombre de producto ya existente
    END
    ELSE
    BEGIN
        INSERT INTO Productos (Nombre_Producto, Descripcion, ID_Categoria, 
                               ID_Marca, Precio, Existencias, Imagen)
        VALUES (LOWER(TRIM(@nombre)), @descripcion, @cat_id, @marca_id, 
                @precio, @Existencias, @imagen);
        SET @OutCode = 0; -- Inserción exitosa
    END
END;
GO

CREATE PROCEDURE sp_updateProducto
    @pro_id INT,
    @nombre NVARCHAR(100),
    @descripcion TEXT,
    @cat_id INT,
    @marca_id INT,
    @precio DECIMAL(10, 2),
    @Existencias INT,
    @imagen VARBINARY(MAX),
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Productos WHERE ID_Producto = @pro_id)
    BEGIN
        UPDATE Productos
        SET Nombre_Producto = LOWER(TRIM(@nombre)),
            Descripcion = @descripcion,
            ID_Categoria = @cat_id,
            ID_Marca = @marca_id,
            Precio = @precio,
            Existencias = @Existencias,
            Imagen = @imagen
        WHERE ID_Producto = @pro_id;

        SET @OutCode = 0; -- Actualización exitosa
    END
    ELSE
    BEGIN
        SET @OutCode = 50016; -- Producto no encontrado
    END
END;
GO

CREATE PROCEDURE upsert_Productos
    @pro_id INT = NULL,  -- ID del producto, opcional para actualizar
    @nombre NVARCHAR(100),
    @descripcion TEXT,
    @nombre_categoria NVARCHAR(100), -- Con esto se obtiene el ID de categoría
    @nombre_marca NVARCHAR(100), -- Con esto se obtiene el ID de marca
    @precio DECIMAL(10, 2),
    @Existencias INT,
    @imagen VARBINARY(MAX),
    @OutCode INT OUTPUT  
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validaciones iniciales con un CTE
        WITH Validaciones AS (
            SELECT
                CASE 
                    WHEN @nombre IS NULL OR LEN(@nombre) > 100 THEN 1
                    WHEN @descripcion IS NULL THEN 1
                    WHEN @nombre_categoria IS NULL OR LEN(@nombre_categoria) > 100 THEN 1
                    WHEN @nombre_marca IS NULL OR LEN(@nombre_marca) > 100 THEN 1
                    WHEN @precio IS NULL OR @precio < 0 THEN 1
                    WHEN @Existencias IS NULL OR @Existencias < 0 THEN 1
                    WHEN @imagen IS NULL THEN 1
                    ELSE 0
                END AS ParamInvalido
        )
        SELECT @OutCode = 50017 FROM Validaciones WHERE ParamInvalido = 1;

        IF @OutCode = 50017
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener el ID de la categoría
        DECLARE @cat_id INT;
        SET @cat_id = dbo.fn_GetCategoryId(@nombre_categoria);

        IF @cat_id IS NULL
        BEGIN
            SET @OutCode = 50014; -- Categoría no encontrada
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener el ID de la marca
        DECLARE @marca_id INT;
        SET @marca_id = dbo.fn_GetBrandId(@nombre_marca);

        IF @marca_id IS NULL
        BEGIN
            SET @OutCode = 50015; -- Marca no encontrada
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Decidir entre inserción o actualización
        IF @pro_id IS NULL
        BEGIN
            -- Insertar nuevo producto
            EXEC sp_insertProducto 
                @nombre, @descripcion, @cat_id, @marca_id, 
                @precio, @Existencias, @imagen, @OutCode OUTPUT;
        END
        ELSE
        BEGIN
            -- Actualizar producto existente
            EXEC sp_updateProducto 
                @pro_id, @nombre, @descripcion, @cat_id, 
                @marca_id, @precio, @Existencias, @imagen, @OutCode OUTPUT;
        END

        -- Confirmar transacción si no hubo errores
        IF @OutCode = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

-- CREATE PROCEDURE upsert_Productos
-- 	@pro_id INT = NULL,  -- ID de la dirección, opcional para actualizar
-- 	@nombre NVARCHAR(100),
-- 	@descripcion TEXT,
-- 	@nombre_categoria NVARCHAR(100), -- Con esto se obtiene el id de categoria
-- 	@nombre_marca NVARCHAR(100), -- Con esto se obtiene el id de marca
-- 	@precio DECIMAL(10, 2),
-- 	@Existencias INT,
-- 	@imagen VARBINARY(MAX),
--     @OutCode INT OUTPUT  
-- AS
-- BEGIN
--      -- Iniciar una transacción
--     BEGIN TRANSACTION;

-- 	-- TRY-CATCH
--     BEGIN TRY

-- 		-- Verificar datos
-- 		DECLARE @InvalidParam BIT = 0;
--         -- Validación de campos requeridos y sus restricciones
--         SET @InvalidParam = CASE 
--             WHEN @nombre IS NULL OR LEN(@nombre) > 100 THEN 1
--             WHEN @descripcion IS NULL THEN 1
--             WHEN @nombre_categoria IS NULL OR LEN(@nombre_categoria) > 100 THEN 1
--             WHEN @nombre_marca IS NULL OR LEN(@nombre_marca) > 100 THEN 1
--             WHEN @precio IS NULL OR @precio < 0 THEN 1
--             WHEN @Existencias IS NULL OR @Existencias < 0 THEN 1
--             WHEN @imagen IS NULL THEN 1
--             ELSE 0
--         END;

--         -- Verificar si hay algún parámetro inválido
--         IF @InvalidParam = 1
--         BEGIN
--             SET @OutCode = 50017;  -- Código genérico de error en parámetros
--             ROLLBACK TRANSACTION;
--             RETURN;
--         END

-- 		-- Obtener id de categoria
-- 		DECLARE @cat_id INT;

-- 		SELECT @cat_id = ID_Categoria
-- 		FROM Categorías 
-- 		WHERE LOWER(TRIM(Nombre_Categoria)) = LOWER(TRIM(@nombre_categoria));
-- 		-- Verificar si se encontró una categoría válida
-- 		IF @cat_id IS NULL
-- 		BEGIN
-- 			SET @OutCode = 50014;  -- Nombre de categoria no existe
-- 			ROLLBACK TRANSACTION;
-- 			RETURN;
-- 		END

-- 		-- Obtener id de marca
-- 		DECLARE @marca_id INT;

-- 		SELECT @marca_id = ID_Marca
-- 		FROM Marcas 
-- 		WHERE LOWER(TRIM(Nombre_Marca)) = LOWER(TRIM(@nombre_marca));
-- 		-- Verificar si se encontró una marca válida
-- 		IF @marca_id IS NULL
-- 		BEGIN
-- 			SET @OutCode = 50015;  -- Nombre de marca no existe
-- 			ROLLBACK TRANSACTION;
-- 			RETURN;
-- 		END


--         -- Verificar si se debe hacer un INSERT o un UPDATE
-- 		DECLARE @name NVARCHAR(100);
-- 		SET @name = LOWER(TRIM(@nombre));
--         IF @pro_id IS NULL -- Realizar un INSERT
--         BEGIN
-- 			-- Verificar si el nombre del producto ya existe
-- 			IF EXISTS (SELECT 1 FROM Productos WHERE LOWER(TRIM(Nombre_Producto)) = @name)
-- 			BEGIN
-- 				SET @OutCode = 50013;  -- Nombre de producto ya existente
-- 				ROLLBACK TRANSACTION;
-- 				RETURN;
-- 			END
-- 			-- Insertar el nuevo producto si no existe
-- 			INSERT INTO Productos(Nombre_Producto, Descripcion, ID_Categoria, 
-- 										ID_Marca, Precio, Existencias, Imagen)
-- 			VALUES (@name, @descripcion, @cat_id, @marca_id, @precio, @Existencias, @imagen);
-- 			SET @OutCode = 0;  -- Éxito en la inserción
--         END
--         ELSE -- Realizar un UPDATE la categoria existe
--         BEGIN
--             IF EXISTS (SELECT 1 FROM Productos WHERE ID_Producto = @pro_id)
--             BEGIN
--                 UPDATE Productos
--                 SET Nombre_Producto = @name,
--                     Descripcion = @descripcion,
-- 					ID_Categoria = @cat_id,
-- 					ID_Marca = @marca_id,
-- 					Existencias = @Existencias,
-- 					Imagen = @imagen
--                 WHERE ID_Producto = @pro_id;
--                 SET @OutCode = 0;  -- Éxito en actualización
--             END
--             ELSE -- Si el ID de Producto no existe o no pertenece al usuario
--             BEGIN
--                 SET @OutCode = 50016; -- Producto no encontrado
--                 ROLLBACK TRANSACTION;
--                 RETURN;
--             END
--         END

--         -- Confirmar la transacción si no hay errores
--         COMMIT TRANSACTION;

--     END TRY
--     BEGIN CATCH
--         -- Hacer ROLLBACK en caso de error
--         IF @@TRANCOUNT > 0
--             ROLLBACK TRANSACTION;

--         -- Capturar y mostrar el mensaje de error
--         DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

--         -- Lanzar el error capturado
--         THROW 50000, @ErrorMessage, 1;
--     END CATCH
-- END;
-- GO


DECLARE @OutCode INT;
EXEC upsert_Productos
	@pro_id = 1,  -- ID de la dirección, opcional para actualizar
	@nombre = 'ASUS no se que',
	@descripcion = 'Es vacilon',
	@nombre_categoria = 'lAptop', -- Con esto se obtiene el id de categoria
	@nombre_marca = 'sNapdrAgon', -- Con esto se obtiene el id de marca
	@precio = 100.5,
	@Existencias = 9,
	@imagen = 1010,
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	------------------------------------
	------- Historial_Inventario -------
	------------------------------------
	-- (Tentativo)



	-----------------------------
	------- Descuentos ----------
	-----------------------------

CREATE PROCEDURE sp_insertDescuento
    @pro_id INT,
    @descuento_porcentaje DECIMAL(5, 2),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @OutCode INT OUTPUT
AS
BEGIN
    -- Verificar si ya existe un descuento vigente para el producto
    IF EXISTS (
        SELECT 1 
        FROM Descuentos 
        WHERE ID_Producto = @pro_id
          AND CAST(GETDATE() AS DATE) BETWEEN Fecha_Inicio AND ISNULL(Fecha_Fin, CAST(GETDATE() AS DATE))
    )
    BEGIN
        SET @OutCode = 50026; -- Ya existe un descuento vigente
        RETURN;
    END

    -- Insertar el nuevo descuento
    INSERT INTO Descuentos (ID_Producto, Descuento_Porcentaje, Fecha_Inicio, Fecha_Fin)
    VALUES (@pro_id, @descuento_porcentaje, @fecha_inicio, @fecha_fin);

    SET @OutCode = 0; -- Inserción exitosa
END;
GO

CREATE PROCEDURE sp_updateDescuento
    @des_id INT,
    @pro_id INT,
    @descuento_porcentaje DECIMAL(5, 2),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @OutCode INT OUTPUT
AS
BEGIN
    -- Verificar si el descuento existe
    IF NOT EXISTS (SELECT 1 FROM Descuentos WHERE ID_Descuento = @des_id)
    BEGIN
        SET @OutCode = 50022; -- Descuento no encontrado
        RETURN;
    END

    -- Verificar si el nuevo rango de fechas entra en conflicto con otro descuento vigente
    IF EXISTS (
        SELECT 1 
        FROM Descuentos 
        WHERE ID_Producto = @pro_id
          AND ID_Descuento <> @des_id
          AND (
                CAST(GETDATE() AS DATE) BETWEEN Fecha_Inicio AND ISNULL(Fecha_Fin, CAST(GETDATE() AS DATE))
                OR @fecha_inicio BETWEEN Fecha_Inicio AND ISNULL(Fecha_Fin, CAST(GETDATE() AS DATE))
              )
    )
    BEGIN
        SET @OutCode = 50026; -- Ya existe un descuento vigente
        RETURN;
    END

    -- Actualizar el descuento
    UPDATE Descuentos
    SET ID_Producto = @pro_id,
        Descuento_Porcentaje = @descuento_porcentaje,
        Fecha_Inicio = @fecha_inicio,
        Fecha_Fin = @fecha_fin
    WHERE ID_Descuento = @des_id;

    SET @OutCode = 0; -- Actualización exitosa
END;
GO

CREATE PROCEDURE upsert_Descuentos
    @des_id INT = NULL, -- ID del descuento, opcional para actualización
    @pro_id INT,        -- ID del producto
    @descuento_porcentaje DECIMAL(5, 2),
    @fecha_inicio DATE,
    @fecha_fin DATE = NULL,
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validaciones iniciales con un CTE
        WITH Validaciones AS (
            SELECT
                CASE 
                    WHEN @pro_id IS NULL THEN 50017 -- Producto requerido
                    WHEN @descuento_porcentaje < 0 OR @descuento_porcentaje > 100 THEN 50023 -- Descuento fuera de rango
                    WHEN @fecha_inicio IS NULL OR @fecha_inicio < CAST(GETDATE() AS DATE) THEN 50024 -- Fecha de inicio inválida
                    WHEN @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio THEN 50025 -- Fecha fin antes de inicio
                    ELSE 0
                END AS ErrorCode
        )
        SELECT @OutCode = ErrorCode FROM Validaciones;

        IF @OutCode IN (50017, 50023, 50024, 50025)
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar que el producto exista
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE ID_Producto = @pro_id)
        BEGIN
            SET @OutCode = 50021; -- Producto no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Decidir entre inserción o actualización
        IF @des_id IS NULL
        BEGIN
            -- Insertar nuevo descuento
            EXEC sp_insertDescuento 
                @pro_id, @descuento_porcentaje, @fecha_inicio, @fecha_fin, @OutCode OUTPUT;
        END
        ELSE
        BEGIN
            -- Actualizar descuento existente
            EXEC sp_updateDescuento 
                @des_id, @pro_id, @descuento_porcentaje, @fecha_inicio, @fecha_fin, @OutCode OUTPUT;
        END

        -- Confirmar la transacción si no hubo errores
        IF @OutCode = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



	------------------------
	------- Pedidos -------- -- Falta descuento
	------------------------

CREATE PROCEDURE upsert_Pedido
    @Correo_Electronico NVARCHAR(150), -- Para obtener el ID del usuario
    @pedido_id INT = NULL,            -- ID del pedido, opcional para actualizar
    @fecha_pedido DATE = NULL,        -- Fecha del pedido, opcional
    @estado NVARCHAR(50),             -- Estado del pedido
    @precio_total DECIMAL(10, 2),     -- Precio total del pedido
    @direccion_id INT,                -- ID de la dirección
    @metodo_pago_id INT,              -- ID del método de pago
    @OutCode INT OUTPUT               -- Código de salida para indicar el resultado
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar parámetros
        DECLARE @InvalidParam BIT = 0;
        SET @InvalidParam = CASE
            WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
            WHEN @estado NOT IN ('entregado', 'enviado', 'en preparación', 'pendiente') THEN 1
            WHEN @precio_total <= 0 THEN 1
            WHEN @direccion_id IS NULL THEN 1
            WHEN @metodo_pago_id IS NULL THEN 1
            ELSE 0
        END;

        IF @InvalidParam = 1
        BEGIN
            SET @OutCode = 50017; -- Parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @Usuario_Existe INT;
        DECLARE @Usuario_Id INT;

        -- Validar que el usuario existe
        SET @Usuario_Existe = (SELECT COUNT(*) FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico);

        IF @Usuario_Existe = 0
        BEGIN
            SET @OutCode = 50004; -- Usuario no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END
        ELSE
        BEGIN
            SET @Usuario_Id = (SELECT ID_Usuario FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico);
        END

        -- Validar dirección y método de pago
        IF NOT EXISTS (SELECT 1 FROM Direcciones WHERE ID_Direccion = @direccion_id AND ID_Usuario = @Usuario_Id)
        BEGIN
            SET @OutCode = 50005; -- Dirección no válida
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Métodos_Pago WHERE ID_Metodo_Pago = @metodo_pago_id AND ID_Usuario = @Usuario_Id)
        BEGIN
            SET @OutCode = 50008; -- Método de pago no válido
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar o actualizar pedido
        IF @pedido_id IS NULL
        BEGIN
            INSERT INTO Pedidos (ID_Usuario, Fecha_Pedido, Estado, Precio_Total, ID_Direccion, ID_Metodo_Pago)
            VALUES (@Usuario_Id, ISNULL(@fecha_pedido, GETDATE()), LOWER(TRIM(@estado)), @precio_total, @direccion_id, @metodo_pago_id);
            SET @OutCode = 0; -- Éxito en inserción
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM Pedidos WHERE ID_Pedido = @pedido_id AND ID_Usuario = @Usuario_Id)
            BEGIN
                UPDATE Pedidos
                SET Fecha_Pedido = ISNULL(@fecha_pedido, Fecha_Pedido),
                    Estado = LOWER(TRIM(@estado)),
                    Precio_Total = @precio_total,
                    ID_Direccion = @direccion_id,
                    ID_Metodo_Pago = @metodo_pago_id
                WHERE ID_Pedido = @pedido_id AND ID_Usuario = @Usuario_Id;
                SET @OutCode = 0; -- Éxito en actualización
            END
            ELSE
            BEGIN
                SET @OutCode = 50018; -- Pedido no encontrado
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



DECLARE @OutCode INT;
EXEC upsert_Pedido
    @Correo_Electronico = 'alduran@estudiantec.com', -- Para obtener el ID del usuario
    @pedido_id = 1,            -- ID del pedido, opcional para actualizar
    @fecha_pedido = NULL,        -- Fecha del pedido, opcional
    @estado = 'en preparación',             -- Estado del pedido
    @precio_total = 21,     -- Precio total del pedido
    @direccion_id = 1,                -- ID de la dirección
    @metodo_pago_id = 2,              -- ID del método de pago
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	---------------------------------
	------- Pedido_Detalle ---------- -- Falta hacer descuento
	---------------------------------

	CREATE PROCEDURE upsert_Pedido_Detalle
    @ID_Pedido INT,
    @ID_Pedido_Detalle INT = NULL, -- Opcional para actualización
    @ID_Producto INT,
    @Cantidad INT,
    @Precio_Unitario DECIMAL(10, 2),
    @OutCode INT OUTPUT
AS
BEGIN
    -- Iniciar una transacción
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validaciones básicas de parámetros
        IF @ID_Pedido IS NULL OR @ID_Producto IS NULL OR @Cantidad <= 0 OR @Precio_Unitario <= 0
        BEGIN
            SET @OutCode = 50017; -- Código de error genérico para parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validar si el pedido existe
        IF NOT EXISTS (SELECT 1 FROM Pedidos WHERE ID_Pedido = @ID_Pedido)
        BEGIN
            SET @OutCode = 500018; -- Pedido no existe
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Validar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE ID_Producto = @ID_Producto)
        BEGIN
            SET @OutCode = 50016; -- Producto no existe
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Determinar si se debe realizar un INSERT o un UPDATE
        IF @ID_Pedido_Detalle IS NULL
        BEGIN
            -- Realizar un INSERT
            INSERT INTO Pedido_Detalle (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario)
            VALUES (@ID_Pedido, @ID_Producto, @Cantidad, @Precio_Unitario);

            SET @OutCode = 0; -- Operación exitosa
        END
        ELSE
        BEGIN
            -- Verificar si el detalle existe y pertenece al pedido
            IF EXISTS (SELECT 1 FROM Pedido_Detalle WHERE ID_Pedido_Detalle = @ID_Pedido_Detalle AND ID_Pedido = @ID_Pedido)
            BEGIN
                -- Realizar un UPDATE
                UPDATE Pedido_Detalle
                SET ID_Producto = @ID_Producto,
                    Cantidad = @Cantidad,
                    Precio_Unitario = @Precio_Unitario
                WHERE ID_Pedido_Detalle = @ID_Pedido_Detalle;

                SET @OutCode = 0; -- Operación exitosa
            END
            ELSE
            BEGIN
                SET @OutCode = 50019; -- Detalle no encontrado o no pertenece al pedido
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Confirmar la transacción
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Realizar ROLLBACK en caso de error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capturar el error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



DECLARE @OutCode INT;
EXEC upsert_Pedido_Detalle
    @ID_Pedido = 1,
    @ID_Pedido_Detalle = NULL, -- Opcional para actualización
    @ID_Producto = 1,
    @Cantidad = 7,
    @Precio_Unitario = 10,
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	------------------------
	------- Carrito --------
	------------------------

CREATE PROCEDURE insert_Carrito
    @Correo_Electronico NVARCHAR(150), -- Para obtener el ID del usuario
    @OutCode INT OUTPUT                -- Código de salida para indicar el resultado
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar parámetros
        IF @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150
        BEGIN
            SET @OutCode = 50017; -- Parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @Usuario_Id INT;
        DECLARE @ID_Carrito INT;

        -- Validar que el usuario existe
        SELECT @Usuario_Id = ID_Usuario
        FROM Usuarios
        WHERE Correo_Electronico = @Correo_Electronico;

        IF @Usuario_Id IS NULL
        BEGIN
            SET @OutCode = 50004; -- Usuario no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si el usuario ya tiene un carrito
        SELECT @ID_Carrito = ID_Carrito
        FROM Carrito
        WHERE ID_Usuario = @Usuario_Id;

        IF @ID_Carrito IS NOT NULL
        BEGIN
            -- Si el carrito ya existe
            SET @OutCode = 50020; -- Éxito, carrito ya existente
            COMMIT TRANSACTION;
            RETURN;
        END

        -- Insertar un nuevo carrito
        INSERT INTO Carrito (ID_Usuario)
        VALUES (@Usuario_Id);

        -- Devolver el nuevo ID del carrito
        SET @OutCode = 0; -- Éxito, carrito creado

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

DECLARE @OutCode INT;
EXEC insert_Carrito
    @Correo_Electronico = 'alduran@estudiantec.com', -- Para obtener el ID del usuario
    @OutCode = @OutCode OUTPUT;
SELECT @OutCode AS Resultado;



	---------------------------------
	------- Carrito_Producto --------
	---------------------------------

CREATE PROCEDURE upsertCarritoProducto
    @Correo_Electronico NVARCHAR(150), -- Para obtener el ID del usuario
    @ID_Producto INT,                  -- ID del producto a agregar o actualizar
    @Cantidad INT,                     -- Cantidad del producto
    @OutCode INT OUTPUT                -- Código de salida para indicar el resultado
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar parámetros
        IF @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150
            OR @ID_Producto IS NULL OR @Cantidad <= 0
        BEGIN
            SET @OutCode = 50017; -- Parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @Usuario_Id INT;
        DECLARE @ID_Carrito INT;
        DECLARE @ID_Carrito_Producto INT;

        -- Obtener el ID del usuario
        SELECT @Usuario_Id = ID_Usuario
        FROM Usuarios
        WHERE Correo_Electronico = @Correo_Electronico;

        IF @Usuario_Id IS NULL
        BEGIN
            SET @OutCode = 50004; -- Usuario no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener el carrito del usuario
        SELECT @ID_Carrito = ID_Carrito
        FROM Carrito
        WHERE ID_Usuario = @Usuario_Id;

        IF @ID_Carrito IS NULL
        BEGIN
            SET @OutCode = 50021; -- Carrito no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si el producto ya está en el carrito
        SELECT @ID_Carrito_Producto = ID_Carrito_Producto
        FROM Carrito_Producto
        WHERE ID_Carrito = @ID_Carrito AND ID_Producto = @ID_Producto;

        IF @ID_Carrito_Producto IS NOT NULL
        BEGIN
            -- Actualizar cantidad del producto existente
            UPDATE Carrito_Producto
            SET Cantidad = Cantidad + @Cantidad
            WHERE ID_Carrito_Producto = @ID_Carrito_Producto;

            SET @OutCode = 0; -- Éxito en actualización
        END
        ELSE
        BEGIN
            -- Insertar nuevo producto en el carrito
            INSERT INTO Carrito_Producto (ID_Carrito, ID_Producto, Cantidad)
            VALUES (@ID_Carrito, @ID_Producto, @Cantidad);

            SET @OutCode = 0; -- Éxito en inserción
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO






	--------------------------
	------- Cupones ----------
	--------------------------

	-- (Tentativo)

	-------------------------------
	------- Pedido_Cupon ----------
	-------------------------------

	-- (Tentativo)

	--------------------------
	------- Reseñas ----------
	--------------------------

CREATE PROCEDURE upsert_Reseña
    @Correo_Electronico NVARCHAR(150), -- Para obtener el ID del usuario
    @reseña_id INT = NULL,             -- ID de la reseña, opcional para actualizar
    @id_producto INT,                  -- ID del producto
    @calificacion INT = NULL,          -- Calificación del producto
    @comentario TEXT = NULL,           -- Comentario de la reseña
    @fecha DATE = NULL,                -- Fecha de la reseña
    @OutCode INT OUTPUT                -- Código de salida para indicar el resultado
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar parámetros
        DECLARE @InvalidParam BIT = 0;
        SET @InvalidParam = CASE
            WHEN @Correo_Electronico IS NULL OR LEN(@Correo_Electronico) > 150 THEN 1
            WHEN @id_producto IS NULL THEN 1
            WHEN @calificacion IS NOT NULL AND (@calificacion < 1 OR @calificacion > 5) THEN 1
            ELSE 0
        END;

        IF @InvalidParam = 1
        BEGIN
            SET @OutCode = 50017; -- Parámetros inválidos
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @Usuario_Existe INT;
        DECLARE @Usuario_Id INT;

        -- Validar que el usuario existe
        SET @Usuario_Existe = (SELECT COUNT(*) FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico);

        IF @Usuario_Existe = 0
        BEGIN
            SET @OutCode = 50004; -- Usuario no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END
        ELSE
        BEGIN
            SET @Usuario_Id = (SELECT ID_Usuario FROM Usuarios WHERE Correo_Electronico = @Correo_Electronico);
        END

        -- Validar que el producto existe
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE ID_Producto = @id_producto)
        BEGIN
            SET @OutCode = 50019; -- Producto no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar o actualizar reseña
        IF @reseña_id IS NULL
        BEGIN
            INSERT INTO Reseñas (ID_Usuario, ID_Producto, Calificacion, Comentario, Fecha)
            VALUES (@Usuario_Id, @id_producto, @calificacion, @comentario, ISNULL(@fecha, GETDATE()));
            SET @OutCode = 0; -- Éxito en inserción
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM Reseñas WHERE ID_Reseña = @reseña_id AND ID_Usuario = @Usuario_Id)
            BEGIN
                UPDATE Reseñas
                SET ID_Producto = @id_producto,
                    Calificacion = @calificacion,
                    Comentario = @comentario,
                    Fecha = ISNULL(@fecha, Fecha)
                WHERE ID_Reseña = @reseña_id AND ID_Usuario = @Usuario_Id;
                SET @OutCode = 0; -- Éxito en actualización
            END
            ELSE
            BEGIN
                SET @OutCode = 50020; -- Reseña no encontrada
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO