----------------------------------
-------- SP's Para deletes -------
----------------------------------

CREATE PROCEDURE sp_deleteUsuario
    @Correo_Electronico NVARCHAR(150), -- Correo electrónico del usuario a eliminar
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validar que el usuario existe
        DECLARE @Usuario_Id INT;
        SET @Usuario_Id = dbo.fn_GetUserId(@Correo_Electronico);

        IF @Usuario_Id IS NULL
        BEGIN
            SET @OutCode = 50004; -- Usuario no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Eliminar registros relacionados en cascada en Carrito_Producto
        DELETE FROM dbo.Carrito_Producto WHERE ID_Carrito IN (SELECT ID_Carrito FROM dbo.Carrito WHERE ID_Usuario = @Usuario_Id);

        -- Eliminar los carritos del usuario
        DELETE FROM dbo.Carrito WHERE ID_Usuario = @Usuario_Id;

        -- Eliminar pedidos, reseñas, direcciones, y métodos de pago del usuario
        DELETE FROM dbo.Pedidos WHERE ID_Usuario = @Usuario_Id;
        DELETE FROM dbo.Reseñas WHERE ID_Usuario = @Usuario_Id;
        DELETE FROM dbo.Direcciones WHERE ID_Usuario = @Usuario_Id;
        DELETE FROM dbo.Métodos_Pago WHERE ID_Usuario = @Usuario_Id;

        -- Eliminar el usuario
        DELETE FROM dbo.Usuarios WHERE ID_Usuario = @Usuario_Id;

        -- Confirmar transacción
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




CREATE PROCEDURE delete_Producto
    @ID_Producto INT,
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE ID_Producto = @ID_Producto)
        BEGIN
            SET @OutCode = 50005; -- Producto no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Eliminar descuentos asociados al producto
        DELETE FROM dbo.Descuentos WHERE ID_Producto = @ID_Producto;

        -- Eliminar productos del carrito y pedidos
        DELETE FROM dbo.Carrito_Producto WHERE ID_Producto = @ID_Producto;
        DELETE FROM dbo.Pedido_Detalle WHERE ID_Producto = @ID_Producto;

        -- Eliminar el producto
        DELETE FROM dbo.Productos WHERE ID_Producto = @ID_Producto;

        -- Confirmar transacción
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



CREATE PROCEDURE sp_deletePedido
    @ID_Pedido INT,
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Verificar si el pedido existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Pedidos WHERE ID_Pedido = @ID_Pedido)
        BEGIN
            SET @OutCode = 50006; -- Pedido no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Eliminar los detalles del pedido
        DELETE FROM dbo.Pedido_Detalle WHERE ID_Pedido = @ID_Pedido;

        -- Eliminar el pedido
        DELETE FROM dbo.Pedidos WHERE ID_Pedido = @ID_Pedido;

        -- Confirmar transacción
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



CREATE PROCEDURE delete_Carrito
    @ID_Carrito INT,
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Verificar si el carrito existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Carrito WHERE ID_Carrito = @ID_Carrito)
        BEGIN
            SET @OutCode = 50007; -- Carrito no encontrado
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Eliminar los productos del carrito
        DELETE FROM dbo.Carrito_Producto WHERE ID_Carrito = @ID_Carrito;

        -- Eliminar el carrito
        DELETE FROM dbo.Carrito WHERE ID_Carrito = @ID_Carrito;

        -- Confirmar transacción
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
