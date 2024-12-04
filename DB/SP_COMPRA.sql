
-------------------------------------------
-------- SP's Para hacer Una Compra -------
-------------------------------------------

-- Actualiza estado del pedido
CREATE PROCEDURE update_estado_pedido
    @id_pedido INT,
    @nuevo_estado NVARCHAR(50),
AS
BEGIN
    BEGIN TRY
        -- Actualizar el estado del pedido
        UPDATE Pedidos
        SET Estado = @nuevo_estado
        WHERE ID_Pedido = @id_pedido;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



-- Precio unitario + descuento
CREATE FUNCTION calcular_precio_unitario
(
    @id_producto INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @precio_unitario DECIMAL(10, 2);

    -- Calcular el precio unitario con descuento aplicado
    SELECT 
        @precio_unitario = CAST(
            p.Precio * (1 - ISNULL(d.Descuento_Porcentaje, 0) / 100) AS DECIMAL(10, 2)
        )
    FROM 
        Productos p
    LEFT JOIN 
        Descuentos d ON p.ID_Producto = d.ID_Producto
        AND CAST(GETDATE() AS DATE) BETWEEN d.Fecha_Inicio AND ISNULL(d.Fecha_Fin, CAST(GETDATE() AS DATE))
    WHERE 
        p.ID_Producto = @id_producto;

    -- Retornar el precio original si no hay descuento o el producto no existe
    RETURN ISNULL(@precio_unitario, 0);
END;
GO



-- Verificar si el carrito del usuario tiene productos
CREATE PROCEDURE check_carrito
    @id_usuario INT,
    @OutCode INT OUTPUT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Carrito c
        INNER JOIN Carrito_Producto cp ON c.ID_Carrito = cp.ID_Carrito
        WHERE c.ID_Usuario = @id_usuario
    )
        SET @OutCode = 0;  -- El carrito tiene productos
    ELSE
        SET @OutCode = 50028;  -- Carrito vacío
END;
GO



-- Calculo de precio total de carrito
CREATE FUNCTION calcular_total_carrito (@id_usuario INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @total DECIMAL(10, 2);

    SELECT 
        @total = SUM(
            CAST(
                p.Precio * (1 - ISNULL(d.Descuento_Porcentaje, 0) / 100) * cp.Cantidad 
                AS DECIMAL(10, 2)
            )
        )
    FROM 
        Carrito c
    INNER JOIN 
        Carrito_Producto cp ON c.ID_Carrito = cp.ID_Carrito
    INNER JOIN 
        Productos p ON cp.ID_Producto = p.ID_Producto
    LEFT JOIN 
        Descuentos d ON p.ID_Producto = d.ID_Producto
        AND CAST(GETDATE() AS DATE) BETWEEN d.Fecha_Inicio AND ISNULL(d.Fecha_Fin, CAST(GETDATE() AS DATE))
    WHERE 
        c.ID_Usuario = @id_usuario;

    -- Retornar el total calculado
    RETURN ISNULL(@total, 0);
END;
GO



-- Checkea si hay suficientes existencias en el inventario
CREATE PROCEDURE sp_check_inventario
    @id_producto INT,
    @cantidad INT,
    @OutCode INT OUTPUT
AS
BEGIN
    IF (SELECT Existencias FROM Productos WHERE ID_Producto = @id_producto) >= @cantidad
        SET @OutCode = 0; -- Suficiente inventario
    ELSE
        SET @OutCode = 50029; -- No hay suficientes existencias
END;
GO



-- Reduce el invetario de un producto
CREATE PROCEDURE reducir_inventario
    @id_producto INT,
    @cantidad INT,
    @OutCode INT OUTPUT
AS
BEGIN
    BEGIN TRY
        -- Reducir inventario
        UPDATE Productos
        SET Existencias = Existencias - @cantidad
        WHERE ID_Producto = @id_producto;

        SET @OutCode = 0; -- Inventario reducido exitosamente
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



-- Vacia el carrito
CREATE PROCEDURE vaciar_carrito
    @id_usuario INT,     -- ID del usuario
    @OutCode INT OUTPUT  -- Código de salida
AS
BEGIN
    BEGIN TRY
        -- Validar que el usuario tiene un carrito
        IF NOT EXISTS (SELECT 1 FROM Carrito WHERE ID_Usuario = @id_usuario)
        BEGIN
            SET @OutCode = 50021; -- Carrito no encontrado para este usuario
            RETURN;
        END

        -- Obtener el ID del carrito del usuario
        DECLARE @id_carrito INT;
        SELECT @id_carrito = ID_Carrito
        FROM Carrito
        WHERE ID_Usuario = @id_usuario;

        -- Eliminar los productos del carrito
        DELETE FROM Carrito_Producto
        WHERE ID_Carrito = @id_carrito;

        -- Si la operación fue exitosa
        SET @OutCode = 0; -- Operación exitosa

    END TRY
    BEGIN CATCH
        -- Manejar errores y establecer un código de error general
        SET @OutCode = 50000; -- Error general

        -- Capturar el mensaje del error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



/*

    carrito = [c1, c2, c3, c4, c5]

    // verificar si hay fondos suficiente para el usuario
    // funcion para verificar que para cada producto dentro del carrito hay existencias

    for i in carrito:
        reducir_inventario
        reducir_fondos


    - confirmar_pedido (Confirmación de un pedido):
        - Transac
        - Crea un pedido
        - Busca en la tabla Carrito_Producto los productos escogidos por esa persona
        - Valida que si hay existencias de ese producto con respecto a la cantidad
        que se pide  en el carrito.
        - Antes de insertar valida si ese producto tiene descuento, aplica
        el descuento en el Precio_Unitario
        - Calcula el precio_unitario * cantidad = total en la tabla pedidos
        - validar que el usuario tiene fondos para pagar el pedido.
        - Llama un SP para restarle las existencias al producto e inserta en Pedido_Detalle
        - Inserta
        - COMMIT
        - Borra (delete) vacia el carrito del usuario -> carrito_producto
        - Lo pone en el historial de pedidos (Ver clase del profe)

    - actualizar_estado (Actualización de estado de un pedido pendiente, en preparación, 
    enviado, entregado) -> usa el upsert pero solo modifica el estado.
*/
