from datetime import date
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import pydoc
import smtplib
from fastapi import FastAPI, File, Form, HTTPException, Query, Request, UploadFile
from app.db import get_db_conn
from app.models import  AddressCheckRequest,  AddressUpdateRequest, CategoriaInput, DescuentoInput, DiscountUpdateRequest, EmailCheckRequest, EmailValidationInput, MarcaInput, MetodoCheckRequest, MetodoPago, OfertaInput, PaymentMethodUpdateRequest, ProductInput, UpdateEstadoPedidoRequest, UpdateUserInput, UpsertResenaRequest,  UserRegisterInput, UserLogInInput, UserUpdateRequest, UsuarioRequest
from app.functions import check_max_payment_methods, check_principal_address, check_principal_method, check_unique_email, filtrar_producto, insert_cart, update_address, update_discount, update_payment_method, update_user, validate_email_format
import pyodbc 
import app.functions

app = FastAPI()

# DEFAULT ROUTE
@app.get("/")
def read_root():
    return {"message": "Bienvenidos al backend de Jaimex :D"}

@app.get("/readQuery")
#def readQuery(query: str):
    #return read_Query(query)
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

@app.post("/registerUser")
#async def register_user_endpoint(user: UserRegisterInput):
    #return register_user(user)
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
            user.Nombre,
            user.Apellido,
            user.Contraseña,
            user.Correo_Electronico,
            user.Telefono,
            user.Tipo_Usuario
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


@app.post("/userLogIn")
#async def user_log_in_endpoint(user: UserLogInInput):
    #return user_Log_In(user)
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


#Nuevos endpoints agregados
@app.get("/filtrar_producto")
async def filtrar_producto_endpoint(
    inNombre: str = Query(..., description="Nombre parcial o total del producto"),
    inMaxPrecio: float = Query(..., description="Precio máximo del producto"),
    inMarca: str = Query(..., description="Marca del producto"),
    inCategoria: str = Query(..., description="Categoría del producto")
):
    return filtrar_producto(inNombre, inMaxPrecio, inMarca, inCategoria)

@app.get("/get_max_price_products")
async def get_max_price_product():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_max_price_products]")

        # Obtener los nombres de las columnas
        columns = [col[0] for col in cursor.description]

        # Convertir las filas en diccionarios
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Verificar si se obtuvieron resultados
        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron productos en la base de datos."
            )

        # Respuesta exitosa
        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(status_code=500, detail=f"Error al obtener los productos: {str(e)}")

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()
    

@app.get("/getAllProducts")
async def get_all_products():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_all_products]")

        # Obtener los nombres de las columnas
        columns = [col[0] for col in cursor.description]

        # Convertir las filas en diccionarios
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Verificar si se obtuvieron resultados
        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron productos en la base de datos."
            )

        # Respuesta exitosa
        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(status_code=500, detail=f"Error al obtener los productos: {str(e)}")

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()

    
# Obtener todos los nombres de marcas
@app.get("/getAllBrandName")
async def get_all_brand_name():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_nombres_marcas]")

        # Obtener los nombres de las columnas
        columns = [col[0] for col in cursor.description]

        # Convertir las filas en diccionarios
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Verificar si se obtuvieron resultados
        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron marcas en la base de datos."
            )

        # Respuesta exitosa
        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(status_code=500, detail=f"Error al obtener los productos: {str(e)}")

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()
    
@app.post("/insertar_carrito")
async def insert_cart_endpoint(correo_electronico: str):
    try:
        # Llamar a la función asíncrona para insertar el carrito
        result = await insert_cart(correo_electronico)
        
        # Verificar el código de salida
        out_code = result["outCode"]
        
        if out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros inválidos")
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        elif out_code == 50020:
            return {"status": "success", "message": "Carrito ya existente"}
        elif out_code == 0:
            return {"status": "success", "message": "Carrito creado exitosamente"}
        else:
            raise HTTPException(status_code=500, detail="Error desconocido")

    except HTTPException as e:
        # Manejo de errores específicos de la API
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.post("/check_max_metodos_pago")
async def check_max_metodos_pago(request: UsuarioRequest):
    try:
        # Llamar a la función para verificar los métodos de pago
        result = check_max_payment_methods(request.usuario_id)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.post("/check_principal_address")
async def check_principal_address_endpoint(request: AddressCheckRequest):
    try:
        # Llamar a la función para verificar la dirección principal
        result = check_principal_address(request.usuario_id, request.dir_id)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Retornar detalles de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.post("/check_principal_metodo")
async def check_principal_metodo_endpoint(request: MetodoCheckRequest):
    try:
        # Llamar a la función para verificar el método principal
        result = check_principal_method(request.usuario_id, request.metodo_id)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.post("/check_unique_email")
async def check_unique_email_endpoint(request: EmailCheckRequest):
    try:
        # Llamar a la función para verificar la unicidad del email
        result = check_unique_email(request.email)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.put("/update_discount")
async def update_discount_endpoint(request: DiscountUpdateRequest):
    try:
        # Llamar a la función para actualizar el descuento
        result = update_discount(
            request.des_id,
            request.pro_id,
            request.descuento_porcentaje,
            request.fecha_inicio,
            request.fecha_fin,
        )
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")


@app.put("/update_address")
async def update_address_endpoint(request: AddressUpdateRequest):
    try:
        # Llamar a la función para actualizar la dirección
        result = update_address(
            request.dir_id,
            request.usuario_id,
            request.direccion,
            request.ciudad,
            request.provincia,
            request.codigo_postal,
            request.pais,
            request.principal,
        )
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")


@app.put("/update_payment_method")
async def update_payment_method_endpoint(request: PaymentMethodUpdateRequest):
    try:
        # Llamar a la función para actualizar el método de pago
        result = update_payment_method(
            request.metodo_id,
            request.usuario_id,
            request.tipo,
            request.detalles,
            request.principal,
        )
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")

@app.post("/update_user")
def update_user(input: UpdateUserInput):
    try:
        # Conectar a la base de datos
        conn = get_db_conn()
        cursor = conn.cursor()

        # Preparar y ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[sp_updateUsuario]
            @ID = ?,
            @Nombre = ?,
            @Apellido = ?,
            @Correo_Electronico = ?,
            @Contraseña = ?,
            @Teléfono = ?,
            @Tipo_Usuario = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode;
        """
        params = (
            input.id, 
            input.nombre.strip(), 
            input.apellido.strip(), 
            input.correo.strip(), 
            input.contrasena, 
            input.numero_tel.strip(), 
            input.tipo_usuario.strip().lower()
        )
        output_code = cursor.execute(query, params).fetchone()

        # Validar si se obtuvo un resultado
        if output_code is None or len(output_code) == 0:
            raise HTTPException(status_code=500, detail="Error al ejecutar el procedimiento almacenado.")

        return {"correo_electronico": input.correo, "out_code": output_code[0]}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar el usuario: {str(e)}")

    finally:
        # Cerrar la conexión
        cursor.close()
        conn.close()


@app.post("/validate_email_format")
async def validate_email_format_endpoint(input_data: EmailValidationInput):
    try:
        # Llamar a la función para validar el correo
        result = validate_email_format(input_data.correo)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")

"""    
@app.post("/upsert_descuentos")
async def upsert_descuentos_endpoint(input_data: UpsertDescuentoInput):
    try:
        # Llamar a la función para ejecutar el procedimiento almacenado
        result = upsert_descuentos(input_data)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Manejo de errores específicos
        raise e

    except Exception as e:
        # Manejo de errores desconocidos
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
    
@app.post("/upsert_direccion")
async def upsert_direccion_endpoint(input_data: UpsertDireccionInput):
    try:
        # Llamada al procedimiento almacenado
        result = upsert_direccion(input_data)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Errores controlados
        raise e

    except Exception as e:
        # Errores no controlados
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")

@app.post("/upsert_metodo_pago")
async def upsert_metodo_pago_endpoint(input_data: UpsertMetodoPagoInput):
    try:
        # Llamar al procedimiento almacenado
        result = upsert_metodo_pago(input_data)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Errores controlados
        raise e

    except Exception as e:
        # Errores no controlados
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
""" 
"""  
@app.post("/upsert_pedido")
async def upsert_pedido(input_data: UpsertPedidoInput):
    try:
        # Llamar al procedimiento almacenado
        result = upsert_pedido(input_data)
        return {"status": "success", "data": result}

    except HTTPException as e:
        # Errores controlados
        raise e

    except Exception as e:
        # Errores no controlados
        raise HTTPException(status_code=500, detail=f"Error desconocido: {str(e)}")
""" 

# FILTROS DE PRODUCTOS
@app.get("/filterProduct")
async def filter_product(
    product_name: str, 
    max_price: float, 
    brand: str, 
    category: str
):
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("""
            EXEC filtrar_producto 
                @inNombre = ?, 
                @inMaxPrecio = ?, 
                @inMarca = ?, 
                @inCategoria = ?;
        """, product_name, max_price, brand, category)

        result_code_row = cursor.fetchone()

        if result_code_row is None:
            raise HTTPException(status_code=500, detail="No se pudo recuperar el código de resultado.")
        
        result_code = result_code_row[0]

        if result_code == 70001:
            return {"resultCode": result_code, "message": "No se encontraron productos con el nombre especificado."}
        elif result_code == 70002:
            return {"resultCode": result_code, "message": "No se encontraron productos dentro del rango de precio."}
        elif result_code == 70003:
            return {"resultCode": result_code, "message": "No se encontraron productos con la marca especificada."}
        elif result_code == 70004:
            return {"resultCode": result_code, "message": "No se encontraron productos en la categoría especificada."}

        rows = cursor.fetchall()
        rows.append(result_code_row)
        print(rows)
        if not rows:
            return {"resultCode": result_code, "message": "No se encontraron productos."}

        products = []
        for row in rows:
            # Extraer los campos que devuelve el procedimiento almacenado
            products.append({
                "ID_Producto": row[0],
                "Nombre_Producto": row[1],
                "Descripcion": row[2],
                "Nombre_Categoria": row[3],
                "Nombre_Marca": row[4],
                "Precio": float(row[5]),
                "Existencias": row[6],
                "URL_Imagen": row[7],
                "Calificacion_Promedio": float(row[8]),
                "Fecha_Creacion": row[9].isoformat() if isinstance(row[9], date) else row[9],  # Manejar fecha
                "IsDescuento": float(row[10])  # Asegurarse de que el descuento se mapee correctamente
            })

        return {"resultCode": 0, "products": products}

    except Exception as e:
        print('ERROR')
        raise HTTPException(status_code=500, detail=f"Error procesando la solicitud: {str(e)}")

    finally:
        cursor.close()
        conn.close()


# Obtener todos los nombres de categorias
@app.get("/getAllCategoryName")
async def get_all_category_name():
    
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Llamada al procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_nombres_categorias]")

        # Obtener los nombres de las columnas
        columns = [col[0] for col in cursor.description]

        # Convertir las filas en diccionarios
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Verificar si se obtuvieron resultados
        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron categorias en la base de datos."
            )

        # Respuesta exitosa
        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(status_code=500, detail=f"Error al obtener los productos: {str(e)}")

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()

@app.get("/get_ofertas")
async def get_ofertas(page_number: int, page_size: int):
    try:
        conn = get_db_conn()  # Conexión a la base de datos
        cursor = conn.cursor()

        # Ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[get_ofertas]
            @PageNumber = ?,
            @PageSize = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (page_number, page_size))

        # Procesar conjuntos de resultados
        out_code = None
        results = []

        while True:
            if cursor.description:  # Verifica si el conjunto tiene filas
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Si el conjunto contiene @OutCode
                    out_code = rows[0][0]
                else:
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Salir del bucle si no hay más conjuntos
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not found.")

        # Manejo según el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Page number or page size is invalid.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored Procedure Error Code: {out_code}")

    except pyodbc.Error as e:
        # Captura errores relacionados con la base de datos
        raise HTTPException(status_code=500, detail=f"Database Error: {str(e)}")
    except Exception as e:
        # Captura errores generales
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {str(e)}")
    finally:
        # Liberar recursos
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()



@app.post("/upsert_carrito_producto")
async def upsert_carrito_producto(
    correo_electronico: str,
    id_producto: int,
    cantidad: int
):
    try:
        conn = get_db_conn()  # Connect to the database
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC [dbo].[upsertCarritoProducto]
            @Correo_Electronico = ?,
            @ID_Producto = ?,
            @Cantidad = ?,
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico, id_producto, cantidad))

        # Process result sets
        out_code = None

        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Check if the result contains @OutCode
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not found.")

        # Handle specific output codes
        if out_code == 0:
            return {"status": "success", "message": "Product successfully upserted in cart."}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid parameters.")
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Cart not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored Procedure Error Code: {out_code}")

    except pyodbc.Error as e:
        # Handle database errors
        raise HTTPException(status_code=500, detail=f"Database Error: {str(e)}")
    except Exception as e:
        # Handle general errors
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {str(e)}")
    finally:
        # Release resources
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.post("/purchase")
async def purchase(id_usuario: int):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Step 1: Fetch the primary address for the user
        query_get_address = """
        SELECT ID_Direccion 
        FROM Direcciones 
        WHERE ID_Usuario = ? AND Principal = 1;
        """
        cursor.execute(query_get_address, (id_usuario,))
        id_direccion = cursor.fetchval()
       

        if not id_direccion:
            raise HTTPException(status_code=400, detail="No valid address found for the user. Please add a primary address.")

        # Step 2: Fetch the primary payment method for the user
        query_get_payment_method = """
        SELECT ID_Metodo_Pago 
        FROM Métodos_Pago 
        WHERE ID_Usuario = ? AND Principal = 1;
        """
        cursor.execute(query_get_payment_method, (id_usuario,))
        id_metodo_pago = cursor.fetchval()

        if not id_metodo_pago:
            raise HTTPException(status_code=400, detail="No valid payment method found for the user.")

        # Step 3: Check if the user's cart has products
        query_check_cart = """
        DECLARE @OutCode INT;
        EXEC check_carrito @id_usuario = ?, @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query_check_cart, (id_usuario,))
        out_code = cursor.fetchval()
        if out_code != 0:
            raise HTTPException(status_code=400, detail="Cart is empty.")

        # Step 4: Calculate the total price of the cart
        query_calculate_total = "SELECT dbo.calcular_total_carrito(?)"
        cursor.execute(query_calculate_total, (id_usuario,))
        precio_total = cursor.fetchval()

        # Step 5: Fetch cart products
        query_get_cart_products = """
        SELECT cp.ID_Producto, cp.Cantidad 
        FROM Carrito_Producto cp
        INNER JOIN Carrito c ON cp.ID_Carrito = c.ID_Carrito
        WHERE c.ID_Usuario = ?;
        """
        cursor.execute(query_get_cart_products, (id_usuario,))
        cart_products = cursor.fetchall()

        # Begin transaction
        conn.autocommit = False
        print(id_direccion,precio_total, id_direccion,id_direccion)
        # Step 6: Create the order
        query_create_order = """
        INSERT INTO Pedidos (ID_Usuario, Fecha_Pedido, Estado, Precio_Total, ID_Direccion, ID_Metodo_Pago)
        OUTPUT INSERTED.ID_Pedido
        VALUES (?, GETDATE(), 'pendiente', ?, ?, ?);
        """
        cursor.execute(query_create_order, (id_usuario, precio_total, id_direccion, id_metodo_pago))
        order_id = cursor.fetchval()

        # Step 7: Process each product in the cart
        for product_id, quantity in cart_products:
            # Check inventory
            query_check_inventory = """
            DECLARE @OutCode INT;
            EXEC sp_check_inventario @id_producto = ?, @cantidad = ?, @OutCode = @OutCode OUTPUT;
            SELECT @OutCode AS OutCode;
            """
            cursor.execute(query_check_inventory, (product_id, quantity))
            out_code = cursor.fetchval()
            if out_code != 0:
                raise HTTPException(status_code=400, detail=f"Product {product_id} has insufficient stock.")

            # Calculate unit price
            query_calculate_price = "SELECT dbo.calcular_precio_unitario(?)"
            cursor.execute(query_calculate_price, (product_id,))
            unit_price = cursor.fetchval()

            # Insert into order details
            query_insert_order_detail = """
            INSERT INTO Pedido_Detalle (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario)
            VALUES (?, ?, ?, ?);
            """
            
            cursor.execute(query_insert_order_detail, (order_id, product_id, quantity, unit_price,))

           
        
            # Step 7: Reduce inventory
            query_reduce_inventory = """
            DECLARE @OutCode INT;
            EXEC reducir_inventario @id_producto = ?, @cantidad = ?, @OutCode = @OutCode OUTPUT;
            SELECT @OutCode AS OutCode;
            """
            cursor.execute(query_reduce_inventory, (product_id, quantity))

            # Fetch the output value
            out_code = None
            while True:
                if cursor.description:  # Check if there is a result set
                    row = cursor.fetchone()
                    if row:
                        out_code = row[0]  # Fetch the first column (OutCode)
                        break
                if not cursor.nextset():
                    break

            if out_code is None or out_code != 0:
                raise HTTPException(status_code=400, detail=f"Failed to reduce inventory for product {product_id}.")
            
            print(f"Inventory successfully reduced for Product ID: {product_id}, {id_usuario}")
            print("Proceeding to empty the cart...")

        # Step 8: Empty the cart
        try:
            query_empty_cart = """
            SET NOCOUNT ON;
            DECLARE @OutCode INT;
            EXEC vaciar_carrito @id_usuario = ?, @OutCode = @OutCode OUTPUT;
            SELECT @OutCode AS OutCode;
            """
            
            cursor.execute(query_empty_cart, (id_usuario,))
            result = cursor.fetchone()
            out_code = result[0] if result else None
            print("outcode ", out_code)
            
            if out_code != 0:
                conn.rollback()
                error_messages = {
                    50021: "No se encontró carrito para este usuario.",
                    50000: "Error general al vaciar el carrito."
                }
                error_message = error_messages.get(out_code, "Failed to empty the cart.")
                raise HTTPException(status_code=400, detail=error_message)
            
            conn.commit()
            return {"status": "success", "order_id": order_id, "precio_total": precio_total}

        except Exception as e:
            conn.rollback()
            print(f"Error en vaciar_carrito: {str(e)}")
            raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

    except Exception as e:
            # Rollback transaction on error
            conn.rollback()
            print(f"Transaction rolled back due to an error: {str(e)}")
            raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

    finally:
            if 'cursor' in locals() and cursor:
                cursor.close()
            if 'conn' in locals() and conn:
                conn.close()



@app.put("/update_direccion")
async def update_direccion(
    dir_id: int,
    usuario_id: int,
    direccion: str,
    ciudad: str,
    provincia: str,
    codigo_postal: str,
    pais: str,
    principal: bool
):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC sp_updateDireccion 
            @dir_id = ?, 
            @Usuario_Id = ?, 
            @direccion = ?, 
            @ciudad = ?, 
            @provincia = ?, 
            @codigo_postal = ?, 
            @pais = ?, 
            @principal = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (dir_id, usuario_id, direccion, ciudad, provincia, codigo_postal, pais, principal))

        # Retrieve the output code
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Handle the output code
        if out_code == 0:
            return {"status": "success", "message": "Address updated successfully."}
        elif out_code == 50005:
            raise HTTPException(status_code=404, detail="Address not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Unknown error occurred. OutCode: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.post("/upsert_direccion")
async def upsert_direccion(
    correo_electronico: str,
    direccion: str,
    ciudad: str,
    provincia: str,
    codigo_postal: str,
    pais: str,
    principal: int  # `principal` as an integer (e.g., 0 or 1)
):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC upsert_dir 
            @Correo_Electronico = ?, 
            @dir_id = NULL,  -- Always NULL for new address insertion
            @direccion = ?, 
            @ciudad = ?, 
            @provincia = ?, 
            @codigo_postal = ?, 
            @pais = ?, 
            @principal = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            correo_electronico,
            direccion,
            ciudad,
            provincia,
            codigo_postal,
            pais,
            principal  # Pass as integer
        ))

        # Retrieve the output code
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Handle the output code
        if out_code == 0:
            return {"status": "success", "message": "Address inserted successfully."}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid parameters.")
        elif out_code == 50005:
            raise HTTPException(status_code=404, detail="Address not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Unknown error occurred. OutCode: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected Error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


# Upsert Producto
@app.post("/upsert_productos")
async def upsert_productos(product: ProductInput):
    try:

        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al upsert_Productos
        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Productos
            @pro_id = ?,
            @nombre = ?, 
            @descripcion = ?, 
            @nombre_categoria = ?, 
            @nombre_marca = ?, 
            @precio = ?, 
            @Existencias = ?, 
            @imagen = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            product.id_producto if product.id_producto is not None else None,
            product.nombre_producto,
            product.descripcion,
            product.categoria,
            product.marca,
            product.precio,
            product.existencias,
            product.url_imagen
        ))

        # Recuperar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Producto procesado exitosamente."}
        elif out_code == 50013:
            raise HTTPException(status_code=404, detail="Ya existe el nombre del producto.")
        elif out_code == 50014:
            raise HTTPException(status_code=404, detail="Categoría no encontrada.")
        elif out_code == 50015:
            raise HTTPException(status_code=404, detail="Marca no encontrada.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error desconocido. Código de salida: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.post("/upsert_categoria")
async def upsert_categoria(categoria: CategoriaInput):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado upsert_Categoria
        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Categoria
            @nombre = ?, 
            @categoria_id = ?, 
            @descripcion = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            categoria.nombre_categoria,
            categoria.id_categoria if categoria.id_categoria is not None else None,
            categoria.descripcion
        ))

        # Recuperar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Categoría procesada exitosamente."}
        elif out_code == 50009:
            raise HTTPException(status_code=404, detail="Nombre de categoría ya existente.")
        elif out_code == 50010:
            raise HTTPException(status_code=404, detail="Categoría no encontrada.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error desconocido. Código de salida: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.post("/upsert_marca")
async def upsert_marca(marca: MarcaInput):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado upsert_Categoria
        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Marca
            @id_marca = ?,
            @nombre = ?, 
            @descripcion = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            marca.id_marca if marca.id_marca is not None else None,
            marca.nombre_marca,
            marca.descripcion
        ))

        # Recuperar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Categoría procesada exitosamente."}
        elif out_code == 50011:
            raise HTTPException(status_code=404, detail = "Nombre de marca ya existente.")
        elif out_code == 50010:
            raise HTTPException(status_code=404, detail="Marca no encontrada.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error desconocido. Código de salida: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.post("/upsert_descuentos")
async def upsert_descuentos(descuento: DescuentoInput):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Descuentos
            @des_id = ?, 
            @pro_id = ?, 
            @descuento_porcentaje = ?, 
            @fecha_inicio = ?, 
            @fecha_fin = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            descuento.des_id if descuento.des_id is not None else None,
            descuento.pro_id,
            descuento.descuento_porcentaje,
            descuento.fecha_inicio,
            descuento.fecha_fin
        ))

        # Recuperar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Descuento procesado exitosamente."}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Producto requerido.")
        elif out_code == 50023:
            raise HTTPException(status_code=400, detail="Descuento fuera de rango.")
        elif out_code == 50024:
            raise HTTPException(status_code=400, detail="Fecha de inicio inválida.")
        elif out_code == 50025:
            raise HTTPException(status_code=400, detail="Fecha fin antes de inicio.")
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        elif out_code == 50026:
            raise HTTPException(status_code=404, detail="Ya existe un descuento vigente.")
        
        else:
            raise HTTPException(status_code=400, detail=f"Error desconocido. Código de salida: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/getAllMarcas")
async def get_all_marcas():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_marcas]")

        # Verificar si hay resultados
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron marcas en la base de datos."
            )

        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener las marcas: {str(e)}"
        )

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()


app.get("/get_resenas")
async def get_resenas(id_producto: int, page_number: int = 1, page_size: int = 10):
    """
    Fetch reviews for a specific product with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_Resenas 
            @id_producto = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_producto, page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50016:
            raise HTTPException(status_code=404, detail="Product not found.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_productos_by_categoria")
async def get_productos_by_categoria(categoria: str):
    """
    Fetch products by category name.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_productosByCat 
            @categoria = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (categoria,))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # If OutCode is in the result set
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains product data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle the output code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50014:
            raise HTTPException(status_code=404, detail="Category not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_historial_pedidos")
async def get_historial_pedidos(usuarioID: int, page_number: int = 1, page_size: int = 10):
    """
    Fetch the order history of a user with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_historial_pedidos 
            @usuarioID = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (usuarioID, page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains order history data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_ventas_por_mes")
async def get_ventas_por_mes(year: int, page_number: int = 1, page_size: int = 10):
    """
    Fetch sales data for a specific year with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_ventas_por_mes 
            @year = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (year, page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains sales data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_ventas_cc")
async def get_ventas_cc(page_number: int = 1, page_size: int = 10):
    """
    Fetch paginated sales grouped by customers and categories.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_ventas_cc 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains sales data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_ventas_cc")
async def get_ventas_cc(page_number: int = 1, page_size: int = 10):
    """
    Fetch paginated sales grouped by customers and categories.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_ventas_cc 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains sales data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_top_categorias")
async def get_top_categorias():
    """
    Fetch the top 3 most purchased categories based on total units sold and products purchased.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        EXEC get_TopCategorias;
        """
        cursor.execute(query)

        # Fetch the results
        results = []
        if cursor.description:  # Check if there is a result set
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            results.extend([dict(zip(columns, row)) for row in rows])

        return {"status": "success", "data": results}

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_top_clientes")
async def get_top_clientes():
    """
    Fetch the top 5 customers based on their total purchases.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        EXEC get_TopClientes;
        """
        cursor.execute(query)

        # Fetch the results
        results = []
        if cursor.description:  # Check if there is a result set
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            results.extend([dict(zip(columns, row)) for row in rows])

        return {"status": "success", "data": results}

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_producto")
async def get_producto(id_producto: int):
    """
    Fetch product details by product ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        EXEC get_producto @id_producto = ?;
        """
        cursor.execute(query, (id_producto,))

        # Fetch the results
        if cursor.description:  # Check if there is a result set
            columns = [column[0] for column in cursor.description]
            row = cursor.fetchone()  # Fetch only one row, as it's a single product
            if row:
                product_details = dict(zip(columns, row))
                return {"status": "success", "data": product_details}
            else:
                raise HTTPException(status_code=404, detail="Product not found.")
        else:
            raise HTTPException(status_code=404, detail="Product not found.")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_destacados")
async def get_destacados():
    """
    Fetch the top 5 best-selling products based on total quantity sold and number of orders.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        EXEC get_Destacados;
        """
        cursor.execute(query)

        # Fetch the results
        results = []
        if cursor.description:  # Check if there is a result set
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            results.extend([dict(zip(columns, row)) for row in rows])

        return {"status": "success", "data": results}

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.post("/upsert_descuentos")
async def upsert_descuentos(descuento: DescuentoInput):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Descuentos
            @des_id = ?, 
            @pro_id = ?, 
            @descuento_porcentaje = ?, 
            @fecha_inicio = ?, 
            @fecha_fin = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (
            descuento.des_id if descuento.des_id is not None else None,
            descuento.pro_id,
            descuento.descuento_porcentaje,
            descuento.fecha_inicio,
            descuento.fecha_fin
        ))

        # Recuperar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:
                    out_code = rows[0][0]
            if not cursor.nextset():
                break

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Descuento procesado exitosamente."}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Producto requerido.")
        elif out_code == 50023:
            raise HTTPException(status_code=400, detail="Descuento fuera de rango.")
        elif out_code == 50024:
            raise HTTPException(status_code=400, detail="Fecha de inicio inválida.")
        elif out_code == 50025:
            raise HTTPException(status_code=400, detail="Fecha fin antes de inicio.")
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        elif out_code == 50026:
            raise HTTPException(status_code=404, detail="Ya existe un descuento vigente.")
        
        else:
            raise HTTPException(status_code=400, detail=f"Error desconocido. Código de salida: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/getAllMarcas")
async def get_all_marcas():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_marcas]")

        # Verificar si hay resultados
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron marcas en la base de datos."
            )

        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener las marcas: {str(e)}"
        )

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()


@app.get("/getAllCategoria")
async def get_all_categoria():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_categorias]")

        # Verificar si hay resultados
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron categorias en la base de datos."
            )

        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener las categorias: {str(e)}"
        )

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()



@app.get("/getAllUsuarios")
async def get_all_usuarios():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_usuarios]")

        # Verificar si hay resultados
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron usuarios en la base de datos."
            )

        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener los usuarios: {str(e)}"
        )

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()


# Nuevo mio TAMARA

@app.get("/getallDescuentos")
async def get_all_descuentos():
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        # Ejecutar el procedimiento almacenado
        cursor.execute("EXEC [dbo].[get_descuentos_admin]")

        # Verificar si hay resultados
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        if not results:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron descuentos en la base de datos."
            )

        return results

    except Exception as e:
        # Manejo de errores generales
        raise HTTPException(
            status_code=500,
            detail=f"Error al obtener los descuentos: {str(e)}"
        )

    finally:
        # Cierre de recursos
        cursor.close()
        conn.close()


@app.get("/get_historial_pedidos_admin")
async def get_historial_pedidos_admin(page_number: int = 1, page_size: int = 10):
    """
    Fetch the order history of a user with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_historial_pedidos_admin 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains order history data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()



@app.post("/update_estado_pedido")
async def update_estado_pedido(request: UpdateEstadoPedidoRequest):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamada al procedimiento almacenado
        cursor.execute(
            "EXEC update_estado_pedido @id_pedido = ?, @nuevo_estado = ?",
            request.id_pedido,
            request.nuevo_estado
        )

        conn.commit()
        cursor.close()
        conn.close()

        return {"status": "success", "message": "Estado del pedido actualizado correctamente."}

    except pyodbc.Error as e:
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"Error al actualizar el pedido: {error_message}")
    


@app.get("/get_user_directions")
async def get_user_directions(correo_electronico: str):
    """
    Fetch all addresses for a user given their email address.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_User_Dir 
            @Correo_Electronico = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico,))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos de direcciones
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_user_pedidos")
async def get_user_pedidos(
    correo_electronico: str,
    page_number: int = Query(1, gt=0, description="Número de página, debe ser mayor que 0"),
    page_size: int = Query(10, gt=0, le=100, description="Cantidad de registros por página, entre 1 y 100")
):
    """
    Fetch paginated orders for a user given their email address.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_userPedidos 
            @Correo_Electronico = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico, page_number, page_size))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Si contiene el código de salida
                    out_code = rows[0][0]
                else:  # Procesa los datos de los pedidos
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Cambia al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió código de salida.")

        # Manejar códigos de salida
        if out_code == 0:
            return {
                "status": "success",
                "page_number": page_number,
                "page_size": page_size,
                "data": results
            }
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros de paginación inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_correo")
async def get_correo(id_usuario: int):
    """
    Fetch the email address for a given user ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @Correo_Electronico NVARCHAR(150);
        DECLARE @OutCode INT;
        EXEC get_Correo 
            @ID_Usuario = ?, 
            @Correo_Electronico = @Correo_Electronico OUTPUT, 
            @OutCode = @OutCode OUTPUT;
        SELECT @Correo_Electronico AS Correo_Electronico, @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Leer los resultados
        correo_electronico = None
        out_code = None

        while True:
            if cursor.description:  # Si hay resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    correo_electronico = result.get("Correo_Electronico")
                    out_code = result.get("OutCode")
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió código de salida.")

        # Manejar el código de salida
        if out_code == 0:
            return {
                "status": "success",
                "correo_electronico": correo_electronico
            }
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_resenas")
async def get_resenas(
    id_producto: int,
    page_number: int = Query(1, gt=0, description="Número de página (debe ser mayor a 0)"),
    page_size: int = Query(10, gt=0, le=100, description="Tamaño de página (entre 1 y 100)")
):
    """
    Fetch reviews for a specific product with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_Resenas 
            @id_producto = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_producto, page_number, page_size))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Si contiene el código de salida
                    out_code = rows[0][0]
                else:  # Si contiene datos de reseñas
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Cambia al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió código de salida.")

        # Manejar el código de salida
        if out_code == 0:
            return {
                "status": "success",
                "page_number": page_number,
                "page_size": page_size,
                "data": results
            }
        elif out_code == 50016:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros de paginación inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.post("/upsert_resena")
async def upsert_resena(request: UpsertResenaRequest):
    """
    Insert or update a review for a product. If no `ID_Reseña` is provided, a new review is inserted.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC upsert_Reseña
            @Correo_Electronico = ?, 
            @reseña_id = NULL, -- Siempre NULL para una nueva reseña
            @id_producto = ?, 
            @calificacion = ?, 
            @comentario = ?, 
            @fecha = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(
            query,
            (
                request.correo_electronico,
                request.id_producto,
                request.calificacion,
                request.comentario,
                request.fecha,
            ),
        )

        # Leer el código de salida
        out_code = None
        while True:
            if cursor.description:  # Si hay resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    out_code = result.get("OutCode")
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió código de salida.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Reseña añadida exitosamente."}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        elif out_code == 50019:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_carrito")
async def get_carrito(id_usuario: int):
    """
    Fetch the shopping cart details for a given user ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_carrito 
            @id_usuario = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos del carrito
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Shopping cart not found for this user.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.delete("/delete_carrito")
async def delete_carrito(id_carrito: int):
    """
    Delete a shopping cart and all its associated products.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC delete_Carrito 
            @ID_Carrito = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_carrito,))

        # Leer el código de salida
        out_code = None
        while True:
            if cursor.description:  # Si hay resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    out_code = result.get("OutCode")
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Carrito eliminado exitosamente."}
        elif out_code == 50007:
            raise HTTPException(status_code=404, detail="Carrito no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.delete("/delete_pedido")
async def delete_pedido(id_pedido: int):
    """
    Delete an order and all its associated details.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC sp_deletePedido 
            @ID_Pedido = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_pedido,))

        # Leer el código de salida
        out_code = None
        while True:
            if cursor.description:  # Si hay resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    out_code = result.get("OutCode")
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Pedido eliminado exitosamente."}
        elif out_code == 50006:
            raise HTTPException(status_code=404, detail="Pedido no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()
@app.delete("/delete_usuario")
async def delete_usuario(correo_electronico: str):
    """
    Endpoint para eliminar un usuario y todos sus datos relacionados.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC sp_deleteUsuario 
            @Correo_Electronico = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, correo_electronico)

        # Procesar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    out_code = result.get("OutCode")
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió un código de salida del procedimiento almacenado.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Usuario eliminado exitosamente."}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.delete("/delete_producto")
async def delete_producto(id_producto: int):
    """
    Endpoint para eliminar un producto y sus registros asociados.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC delete_Producto 
            @ID_Producto = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, id_producto)

        # Procesar el código de salida
        out_code = None
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    result = dict(zip(columns, row))
                    out_code = result.get("OutCode")
            if not cursor.nextset():
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió un código de salida del procedimiento almacenado.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Producto eliminado exitosamente."}
        elif out_code == 50005:
            raise HTTPException(status_code=404, detail="Producto no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_ofertas")
async def get_ofertas(page_number: int = Query(1, gt=0), page_size: int = Query(10, gt=0)):
    """
    Endpoint para obtener productos con ofertas vigentes, con soporte para paginación.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_ofertas 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, page_number, page_size)

        # Inicializar variables
        out_code = None
        ofertas = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verificar si es el código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es el conjunto de datos de las ofertas
                    ofertas.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="No se devolvió un código de salida del procedimiento almacenado.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": ofertas}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Parámetros de paginación inválidos.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_user_metodo")
async def get_user_metodo(correo_electronico: str):
    """
    Obtener todos los métodos de pago de un usuario por correo electrónico.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_User_Metodo
            @Correo_Electronico = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico,))

        # Procesar los resultados
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de datos del método de pago
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_usuario_by_id")
async def get_usuario_by_id(id_usuario: int):
    """
    Fetch user details by their ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_UsuarioById 
            @id_usuario = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Inicializar variables
        out_code = None
        user_data = None

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos del usuario
                    if rows:
                        user_data = dict(zip(columns, rows[0]))
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": user_data}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_usuario_by_id")
async def get_usuario_by_id(id_usuario: int):
    """
    Fetch user details by their ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_UsuarioById 
            @id_usuario = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Inicializar variables
        out_code = None
        user_data = None

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos del usuario
                    if rows:
                        user_data = dict(zip(columns, rows[0]))
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": user_data}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.delete("/delete_producto_from_carrito")
async def delete_producto_from_carrito(id_carrito: int, id_producto: int):
    """
    Delete a specific product from a shopping cart.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC delete_ProductoFromCarrito 
            @ID_Carrito = ?, 
            @ID_Producto = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_carrito, id_producto))

        # Leer el código de salida
        out_code = None
        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    out_code = row[0] if "OutCode" in columns else None
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Product successfully removed from cart."}
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Shopping cart not found.")
        elif out_code == 50031:
            raise HTTPException(status_code=404, detail="Product not found in the cart.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_ventas_por_mes_gui")
async def get_ventas_por_mes_gui(year: int, page_number: int = 1, page_size: int = 10):
    """
    Fetch sales data grouped by months for a specific year with pagination.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Call the stored procedure
        query = """
        DECLARE @OutCode INT;
        EXEC get_ventas_por_mes_GUI 
            @year = ?, 
            @PageNumber = ?, 
            @PageSize = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (year, page_number, page_size))

        # Fetch OutCode and results
        out_code = None
        results = []

        while True:
            if cursor.description:  # Check if there is a result set
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Fetch the output code if present
                    for row in rows:
                        out_code = row[0]
                else:  # If the result set contains sales data
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Move to the next result set
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Handle out_code
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50017:
            raise HTTPException(status_code=400, detail="Invalid pagination parameters.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_usuario_by_id")
async def get_usuario_by_id(id_usuario: int):
    """
    Fetch user details by their ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_UsuarioById 
            @id_usuario = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Inicializar variables
        out_code = None
        user_data = None

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos del usuario
                    if rows:
                        user_data = dict(zip(columns, rows[0]))
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": user_data}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()



@app.delete("/delete_producto_from_carrito")
async def delete_producto_from_carrito(id_carrito: int, id_producto: int):
    """
    Delete a specific product from a shopping cart.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC delete_ProductoFromCarrito 
            @ID_Carrito = ?, 
            @ID_Producto = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_carrito, id_producto))

        # Leer el código de salida
        out_code = None
        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                for row in rows:
                    out_code = row[0] if "OutCode" in columns else None
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Product successfully removed from cart."}
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Shopping cart not found.")
        elif out_code == 50031:
            raise HTTPException(status_code=404, detail="Product not found in the cart.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.post("/insertMetodoPago")
async def insert_metodo_pago(metodo_pago: MetodoPago):
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Declarar parámetro de salida
        out_code = None

        # Ejecutar el procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC sp_insertMetodoPago 
            @Usuario_Id = ?, 
            @tipo = ?, 
            @detalles = ?, 
            @principal = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(
            query,
            metodo_pago.Usuario_Id,
            metodo_pago.tipo.strip().lower(),
            metodo_pago.detalles.strip().lower(),
            int(metodo_pago.principal)  # Convertir booleano a entero (1 o 0)
        )

        # Leer el parámetro de salida
        result = cursor.fetchone()
        if result:
            out_code = result[0]

        # Verificar el código de salida
        if out_code == 0:
            return {"status": "success", "message": "Método de pago insertado correctamente"}
        else:
            raise HTTPException(status_code=400, detail="Error al insertar el método de pago")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_user_metodo")
async def get_user_metodo(correo_electronico: str):
    """
    Obtener todos los métodos de pago de un usuario por correo electrónico.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_User_Metodo
            @Correo_Electronico = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico,))

        # Procesar los resultados
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de datos del método de pago
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mover al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        else:
            raise HTTPException(status_code=400, detail=f"Error del procedimiento almacenado. Código: {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Error en la base de datos: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.get("/get_carrito")
async def get_carrito(id_usuario: int):
    """
    Fetch the shopping cart details for a given user ID.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_carrito 
            @id_usuario = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (id_usuario,))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos del carrito
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50021:
            raise HTTPException(status_code=404, detail="Shopping cart not found for this user.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()

@app.get("/get_user_directions")
async def get_user_directions(correo_electronico: str):
    """
    Fetch all addresses for a user given their email address.
    """
    try:
        conn = get_db_conn()
        cursor = conn.cursor()

        # Llamar al procedimiento almacenado
        query = """
        DECLARE @OutCode INT;
        EXEC get_User_Dir 
            @Correo_Electronico = ?, 
            @OutCode = @OutCode OUTPUT;
        SELECT @OutCode AS OutCode;
        """
        cursor.execute(query, (correo_electronico,))

        # Inicializar variables
        out_code = None
        results = []

        while True:
            if cursor.description:  # Si hay un conjunto de resultados
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                if "OutCode" in columns:  # Verifica si es el resultado del código de salida
                    for row in rows:
                        out_code = row[0]
                else:  # Si es un conjunto de resultados con datos de direcciones
                    results.extend([dict(zip(columns, row)) for row in rows])
            if not cursor.nextset():  # Mueve al siguiente conjunto de resultados
                break

        if out_code is None:
            raise HTTPException(status_code=500, detail="Output code not returned from stored procedure.")

        # Manejar el código de salida
        if out_code == 0:
            return {"status": "success", "data": results}
        elif out_code == 50004:
            raise HTTPException(status_code=404, detail="User not found.")
        else:
            raise HTTPException(status_code=400, detail=f"Stored procedure error: OutCode {out_code}")

    except pyodbc.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()