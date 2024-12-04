from http.client import HTTPException
import pydoc
from app.db import get_db_conn
from app.models import UpsertDescuentoInput, UpsertDireccionInput, UpsertMetodoPagoInput, UpsertPedidoInput, UserRegisterInput, UserLogInInput
import pyodbc 
import asyncio

def read_Query(query: str):
    try:
        # Conexión a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Ejecutar la consulta
        cursor.execute(query)

        # Obtener los nombres de las columnas
        columns = [col[0] for col in cursor.description]

        # Convertir las filas en diccionarios
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Cerrar la conexión
        conn.close()

        # Retornar los resultados en formato JSON
        return results

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# REGISTRO DE USUARIO
async def register_user(user: UserRegisterInput):
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute(
            """
            DECLARE @ResultCode INT;

            EXEC [dbo].[Registro_Usuario] 
                @inputNombre = ?, 
                @inputApellido = ?, 
                @inputPassword = ?, 
                @inputCorreo = ?, 
                @inputNumTelefono = ?, 
                @inputTipo = ?, 
                @outResult = @ResultCode OUTPUT;

            SELECT @ResultCode AS ResultCode;
            """,
            user.nombre,
            user.apellido,
            user.contrasena,
            user.correo,
            user.telefono,
            user.tipo
        )

        # Obtener el resultado del parámetro de salida
        result = cursor.fetchone()

        # Verificar si obtuvimos un resultado
        if result is None:
            raise HTTPException(status_code=500, detail="No se obtuvo ningún resultado del procedimiento almacenado.")
        
        # Obtener el código de resultado
        resultCode = result[0]

        # Manejo de errores basado en el código de salida
        if resultCode != 0:
            errorMessage = f"Error con código: {resultCode}"

            # Personaliza los mensajes de error
            if resultCode == 60001:
                errorMessage = "El número de teléfono ya está registrado."
            elif resultCode == 60002:
                errorMessage = "El correo electrónico ya está registrado."
            elif resultCode == 60003:
                errorMessage = "El correo electrónico tiene un formato incorrecto."
            
            return {"resultCode": resultCode, "errorMessage": errorMessage}
        
        return {"resultCode": resultCode}

    except Exception as e:
        # Captura de errores generales
        print("Error en el endpoint:", str(e))
        return 0

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()


# LOG IN
async def user_Log_In(user: UserLogInInput):
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute(
            """
            DECLARE @ResultCode INT, @ResultUserID INT, @ResultType NVARCHAR(255);

            EXEC [dbo].[log_in] 
                @inputCorreo = ?, 
                @inputPassword = ?, 
                @outResult = @ResultCode OUTPUT, 
                @outType = @ResultType OUTPUT, 
                @outUserID = @ResultUserID OUTPUT;

            SELECT @ResultCode AS ResultCode, @ResultType AS ResultType ,@ResultUserID AS ResultUserID;
            """,
            user.electronicMail,
            user.profilePassword
        )

        # Obtener el resultado del procedimiento
        result = cursor.fetchone()
        if result is None:
            raise HTTPException(
                status_code=500,
                detail="El procedimiento almacenado no devolvió ningún resultado."
            )

        resultCode, resultType, resultUserID  = result[0], result[1], result[2]

        # Manejo de códigos de error
        if resultCode != 0:
            errorMessage = "Error desconocido."
            if resultCode == 60004:
                errorMessage = "El correo electrónico no está registrado."
            elif resultCode == 60005:
                errorMessage = "El correo electrónico tiene un formato inválido."
            elif resultCode == 60006:
                errorMessage = "Las credenciales no coinciden."

            return {
                "resultCode": resultCode,
                "errorMessage": errorMessage,
                "userID": None,
                "userType": None
            }

        # Respuesta exitosa
        return {
            "resultCode": resultCode,
            "errorMessage": None,
            "userID": resultUserID,
            "userType": resultType
        }

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()

def filtrar_producto(inNombre: str, inMaxPrecio: float, inMarca: str, inCategoria: str):
    try:
        # Conexión a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        cursor.execute(
            """
            EXEC [dbo].[filtrar_producto]
                @inNombre = ?,
                @inMaxPrecio = ?,
                @inMarca = ?,
                @inCategoria = ?
            """,
            inNombre,
            inMaxPrecio,
            inMarca,
            inCategoria
        )

        # Recuperar los resultados
        results = cursor.fetchall()
        columns = [column[0] for column in cursor.description]

        # Verificar si se devolvió un código de error
        if len(results) == 1 and "Result" in columns[0]:
            resultCode = results[0][0]
            errorMessage = {
                70001: "No se encontraron productos con el nombre indicado.",
                70002: "No se encontraron productos con el precio especificado.",
                70003: "No se encontraron productos con la marca indicada.",
                70004: "No se encontraron productos en la categoría indicada."
            }.get(resultCode, "Error desconocido.")
            return {"resultCode": resultCode, "errorMessage": errorMessage}

        # Convertir resultados en formato JSON
        productos = [dict(zip(columns, row)) for row in results]
        return {"resultCode": 0, "productos": productos}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en la operación: {str(e)}")
    finally:
        cursor.close()
        conn.close()

def get_max_price_products():
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_max_price_products]")

        # Obtener el resultado
        result = cursor.fetchone()

        # Verificar si hay resultados
        if result is None:
            raise HTTPException(status_code=404, detail="No se encontró información sobre precios.")

        # Retornar el precio máximo
        return {"maxPrice": result[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener el precio máximo: {str(e)}")

    finally:
        # Cierre de conexión
        cursor.close()
        conn.close()


def get_category_names():
    try:
        # Conectar a la base de datos
        conn = get_db_conn()  # Asumiendo que tienes una función `get_db_conn` para conectar a la base de datos
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_nombres_categorias]")

        # Obtener los resultados
        result = cursor.fetchall()

        # Verificar si hay resultados
        if not result:
            raise HTTPException(status_code=404, detail="No se encontraron categorías.")

        # Retornar los nombres de las categorías
        categories = [row[0] for row in result]  # Suponiendo que el nombre de la categoría está en la primera columna

        return {"categories": categories}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener las categorías: {str(e)}")

    finally:
        # Cierre de la conexión
        cursor.close()
        conn.close()

def get_brand_names():
    try:
        # Conectar a la base de datos
        conn = get_db_conn()  # Asume que tienes una función `get_db_conn` para obtener la conexión
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_nombres_marcas]")

        # Obtener los resultados
        result = cursor.fetchall()

        # Verificar si hay resultados
        if not result:
            raise HTTPException(status_code=404, detail="No se encontraron marcas.")

        # Extraer los nombres de las marcas
        brands = [row[0] for row in result]  # Suponiendo que el nombre de la marca está en la primera columna

        return {"brands": brands}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener las marcas: {str(e)}")

    finally:
        # Cierre de conexión
        cursor.close()
        conn.close()


async def insert_cart(correo_electronico: str):
    return await asyncio.to_thread(insert_cart_sync, correo_electronico)
def insert_cart_sync(correo_electronico: str):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar el parámetro de salida
        out_code = 0

        # Ejecutar el procedimiento almacenado
        cursor.execute("""
            DECLARE @OutCode INT;
            EXEC [dbo].[insert_Carrito] @Correo_Electronico = ?, @OutCode = @OutCode OUTPUT;
            SELECT @OutCode;
        """, correo_electronico)

        # Obtener el código de salida
        out_code = cursor.fetchone()[0]

        # Retornar el código de salida
        return {"outCode": out_code}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al insertar el carrito: {str(e)}")

    finally:
        # Cierre de conexión
        cursor.close()
        conn.close()

def check_max_payment_methods(usuario_id: int):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Configurar y ejecutar el procedimiento almacenado con parámetros
        output_code = cursor.execute(
            """
            DECLARE @OutCode INT;
            EXEC [dbo].[sp_checkMaxMetodosPago] 
                @Usuario_Id = ?, 
                @OutCode = @OutCode OUTPUT;
            SELECT @OutCode;
            """,
            usuario_id
        ).fetchone()

        # Verificar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"usuario_id": usuario_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al verificar métodos de pago: {str(e)}")

    finally:
        # Cerrar conexión
        cursor.close()
        conn.close()


def check_principal_address(usuario_id: int, dir_id: int = None):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_checkPrincipalAddress] 
            @Usuario_Id = ?, 
            @dir_id = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (usuario_id, dir_id)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"usuario_id": usuario_id, "dir_id": dir_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al verificar la dirección principal: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def check_principal_method(usuario_id: int, metodo_id: int = None):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_checkPrincipalMetodo]
            @Usuario_Id = ?,
            @metodo_id = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (usuario_id, metodo_id)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"usuario_id": usuario_id, "metodo_id": metodo_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al verificar el método de pago principal: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def check_unique_email(email: str):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_checkUniqueEmail]
            @Correo_Electronico = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (email,)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"email": email, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al verificar la unicidad del correo: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def update_discount(
    des_id: int, pro_id: int, descuento_porcentaje: float, fecha_inicio: str, fecha_fin: str
):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_updateDescuento]
            @des_id = ?,
            @pro_id = ?,
            @descuento_porcentaje = ?,
            @fecha_inicio = ?,
            @fecha_fin = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (des_id, pro_id, descuento_porcentaje, fecha_inicio, fecha_fin)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"des_id": des_id, "pro_id": pro_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el descuento: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()


def update_address(
    dir_id: int,
    usuario_id: int,
    direccion: str,
    ciudad: str,
    provincia: str,
    codigo_postal: str,
    pais: str,
    principal: bool,
):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_updateDireccion]
            @dir_id = ?,
            @Usuario_Id = ?,
            @direccion = ?,
            @ciudad = ?,
            @provincia = ?,
            @codigo_postal = ?,
            @pais = ?,
            @principal = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            dir_id,
            usuario_id,
            direccion,
            ciudad,
            provincia,
            codigo_postal,
            pais,
            principal,
        )
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"dir_id": dir_id, "usuario_id": usuario_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar la dirección: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def update_payment_method(
    metodo_id: int,
    usuario_id: int,
    tipo: str,
    detalles: str,
    principal: bool,
):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_updateMetodoPago]
            @metodo_id = ?,
            @Usuario_Id = ?,
            @tipo = ?,
            @detalles = ?,
            @principal = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (metodo_id, usuario_id, tipo, detalles, principal)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"metodo_id": metodo_id, "usuario_id": usuario_id, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el método de pago: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def update_user(
    nombre: str,
    apellido: str,
    correo_electronico: str,
    contrasena: str,
    telefono: str,
    tipo_usuario: str,
):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_updateUsuario]
            @Nombre = ?,
            @Apellido = ?,
            @Correo_Electronico = ?,
            @Contraseña = ?,
            @Teléfono = ?,
            @Tipo_Usuario = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (nombre, apellido, correo_electronico, contrasena, telefono, tipo_usuario)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"correo_electronico": correo_electronico, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el usuario: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def validate_email_format(correo: str):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_validateEmailFormat]
            @Correo_Electronico = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (correo,)
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"correo": correo, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al validar el formato del correo: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def upsert_descuentos(input_data: UpsertDescuentoInput):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[upsert_Descuentos]
            @des_id = ?,
            @pro_id = ?,
            @descuento_porcentaje = ?,
            @fecha_inicio = ?,
            @fecha_fin = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            input_data.des_id,
            input_data.pro_id,
            input_data.descuento_porcentaje,
            input_data.fecha_inicio,
            input_data.fecha_fin,
        )
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al realizar la operación: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()

def upsert_direccion(input_data: UpsertDireccionInput):
    try:
        # Conexión a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Query para ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[upsert_dir]
            @Correo_Electronico = ?,
            @dir_id = ?,
            @direccion = ?,
            @ciudad = ?,
            @provincia = ?,
            @codigo_postal = ?,
            @pais = ?,
            @principal = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            input_data.correo_electronico,
            input_data.dir_id,
            input_data.direccion,
            input_data.ciudad,
            input_data.provincia,
            input_data.codigo_postal,
            input_data.pais,
            int(input_data.principal),  # Convertir booleano a 0/1
        )
        output_code = cursor.execute(query, params).fetchone()

        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al realizar la operación: {str(e)}")

    finally:
        cursor.close()
        conn.close()

def upsert_metodo_pago(input_data: UpsertMetodoPagoInput):
    try:
        # Conexión a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Query para ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[upsert_Metodo_Pago]
            @Correo_Electronico = ?,
            @metodo_id = ?,
            @tipo = ?,
            @detalles = ?,
            @principal = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            input_data.correo_electronico,
            input_data.metodo_id,
            input_data.tipo,
            input_data.detalles,
            int(input_data.principal),  # Convertir booleano a 0/1
        )
        cursor.execute(query, params)

        # Obtener el código de salida del procedimiento almacenado
        output_code = cursor.fetchval()

        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"out_code": output_code}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al realizar la operación: {str(e)}")

    finally:
        cursor.close()
        conn.close()        


def upsert_pedido(input_data: UpsertPedidoInput):
    try:
        # Conexión a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Query para ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[upsert_Pedido]
            @Correo_Electronico = ?,
            @pedido_id = ?,
            @fecha_pedido = ?,
            @estado = ?,
            @precio_total = ?,
            @direccion_id = ?,
            @metodo_pago_id = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            input_data.correo_electronico,
            input_data.pedido_id,
            input_data.fecha_pedido,
            input_data.estado,
            input_data.precio_total,
            input_data.direccion_id,
            input_data.metodo_pago_id,
        )
        cursor.execute(query, params)

        # Obtener el código de salida del procedimiento almacenado
        output_code = cursor.fetchval()

        if output_code is None:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"out_code": output_code}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al realizar la operación: {str(e)}")

    finally:
        cursor.close()
        conn.close()



