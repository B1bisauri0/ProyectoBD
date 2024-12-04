CREATE TRIGGER trg_BloquearPedidosSinInventario
ON Pedido_Detalle
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @ID_Producto INT;
    DECLARE @Cantidad INT;
    DECLARE @Inventario_Disponible INT;
    DECLARE @OutCode INT;

    -- Obtener el ID del producto y la cantidad del detalle insertado o actualizado
    SELECT 
        @ID_Producto = ID_Producto,
        @Cantidad = Cantidad
    FROM INSERTED;

    -- Verificar si el producto tiene suficiente inventario
    SELECT @Inventario_Disponible = Existencias
    FROM Productos
    WHERE ID_Producto = @ID_Producto;

    IF @Inventario_Disponible < @Cantidad
    BEGIN
        -- Si no hay suficiente inventario, se cancela la operación
        SET @OutCode = 50020; -- Producto sin inventario suficiente
        RAISERROR('No hay suficiente inventario para el producto %d. Inventario disponible: %d, cantidad solicitada: %d.',
            16, 1, @ID_Producto, @Inventario_Disponible, @Cantidad);

        -- Realizar ROLLBACK de la operación
        ROLLBACK TRANSACTION;
    END
END;
GO



CREATE TRIGGER trg_AlertaInventarioBajo
ON Productos
AFTER UPDATE
AS
BEGIN
    DECLARE @ID_Producto INT;
    DECLARE @Nombre_Producto VARCHAR(100);
    DECLARE @Existencias INT;

    -- Obtener los valores actualizados del producto
    SELECT 
        @ID_Producto = ID_Producto,
        @Nombre_Producto = Nombre_Producto,
        @Existencias = Existencias
    FROM INSERTED;

    -- Verificar si el inventario está bajo (por ejemplo, menor o igual a 10)
    IF @Existencias <= 10
    BEGIN
        -- Enviar una alerta o realizar alguna acción (puedes usar RAISERROR para generar un mensaje de alerta)
        RAISERROR('¡Alerta! El inventario del producto "%s" (ID: %d) está bajo. Existencias: %d', 16, 1, @Nombre_Producto, @ID_Producto, @Existencias);
        
    END
END;
GO
