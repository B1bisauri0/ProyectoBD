import pydoc
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from datetime import date

class UserRegisterInput(BaseModel):
    Nombre: str
    Apellido: str
    Contraseña: str
    Correo_Electronico: str
    Telefono: str
    Tipo_Usuario: str

class UserLogInInput(BaseModel):
    electronicMail: str
    profilePassword: str

class UsuarioRequest(BaseModel):
    usuario_id: int

class AddressCheckRequest(BaseModel):
    usuario_id: int
    dir_id: int = None

class MetodoCheckRequest(BaseModel):
    usuario_id: int
    metodo_id: int = None  

class EmailCheckRequest(BaseModel):
    email: EmailStr

class DiscountUpdateRequest(BaseModel):
    des_id: int
    pro_id: int
    descuento_porcentaje: float = Field(..., gt=0, le=100, description="Porcentaje entre 0 y 100")
    fecha_inicio: date
    fecha_fin: date

class AddressUpdateRequest(BaseModel):
    dir_id: int
    usuario_id: int
    direccion: str = Field(..., max_length=255, description="Dirección de hasta 255 caracteres")
    ciudad: str = Field(..., max_length=100, description="Ciudad de hasta 100 caracteres")
    provincia: str = Field(..., max_length=100, description="Provincia de hasta 100 caracteres")
    codigo_postal: str = Field(..., max_length=20, description="Código postal de hasta 20 caracteres")
    pais: str = Field(..., max_length=50, description="País de hasta 50 caracteres")
    principal: bool

class PaymentMethodUpdateRequest(BaseModel):
    metodo_id: int
    usuario_id: int
    tipo: str = Field(..., max_length=50, description="Tipo del método de pago, hasta 50 caracteres")
    detalles: str = Field(..., max_length=255, description="Detalles del método de pago, hasta 255 caracteres")
    principal: bool

class UserUpdateRequest(BaseModel):
    nombre: str = Field(..., max_length=100, description="Nombre del usuario, hasta 100 caracteres")
    apellido: str = Field(..., max_length=100, description="Apellido del usuario, hasta 100 caracteres")
    correo_electronico: EmailStr
    contrasena: str = Field(..., max_length=255, description="Contraseña del usuario, hasta 255 caracteres")
    telefono: str = Field(..., max_length=20, description="Teléfono del usuario, hasta 20 caracteres")
    tipo_usuario: str = Field(..., max_length=50, description="Tipo de usuario, hasta 50 caracteres")

class EmailValidationInput(BaseModel):
    correo: str
 
class UpsertDescuentoInput(BaseModel):
    des_id: Optional[int] = Field(None, description="ID del descuento (para actualización)")
    pro_id: int = Field(..., description="ID del producto")
    descuento_porcentaje: float = Field(..., ge=0, le=100, description="Porcentaje de descuento (0-100)")
    fecha_inicio: date = Field(..., description="Fecha de inicio del descuento")
    fecha_fin: Optional[date] = Field(None, description="Fecha de finalización del descuento (opcional)")

class UpsertDireccionInput(BaseModel):
    correo_electronico: EmailStr = Field(..., description="Correo electrónico del usuario")
    dir_id: Optional[int] = Field(None, description="ID de la dirección (opcional para actualización)")
    direccion: str = Field(..., max_length=255, description="Dirección del usuario")
    ciudad: str = Field(..., max_length=100, description="Ciudad")
    provincia: str = Field(..., max_length=100, description="Provincia")
    codigo_postal: str = Field(..., max_length=20, description="Código postal")
    pais: str = Field(..., max_length=50, description="País")
    principal: bool = Field(..., description="Si la dirección es principal")

class UpsertMetodoPagoInput(BaseModel):
    correo_electronico: EmailStr = Field(..., description="Correo electrónico del usuario")
    metodo_id: Optional[int] = Field(None, description="ID del método de pago (opcional para actualización)")
    tipo: str = Field(..., max_length=50, description="Tipo de método de pago")
    detalles: str = Field(..., max_length=255, description="Detalles del método de pago")
    principal: bool = Field(..., description="Si el método de pago es principal")

class UpsertPedidoInput(BaseModel):
    correo_electronico: str
    pedido_id: Optional[int] = None
    fecha_pedido: Optional[str] = None  # YYYY-MM-DD
    estado: str
    precio_total: float
    direccion_id: int
    metodo_pago_id: int


class Product(BaseModel):
    id_producto: Optional[int] = None
    nombre_producto: str
    descripcion: str
    categoria: str
    marca: str
    precio: float
    existencias: int
    url_imagen: str
    calificacion_promedio: float
    fecha_creacion: str


class PurchaseResponse(BaseModel):
    user_id: int
    total: float
    message: str

class AddressRequest(BaseModel):
    correo_electronico: str
    dir_id: int = None  # Optional, for updating an address
    direccion: str
    ciudad: str
    provincia: str
    codigo_postal: str
    pais: str
    principal: bool

class ProductInput(BaseModel):
    id_producto: int | None = None
    nombre_producto: str
    descripcion: str
    categoria: str
    marca: str
    precio: float
    existencias: int
    url_imagen: str

class CategoriaInput(BaseModel):
    id_categoria: int | None = None
    nombre_categoria: str
    descripcion: str

class MarcaInput(BaseModel):
    id_marca: int | None = None
    nombre_marca: str
    descripcion: str

class DescuentoInput(BaseModel):
    des_id: int | None = None
    pro_id: int
    descuento_porcentaje: float
    fecha_inicio: str
    fecha_fin: str | None = None

class OfertaInput(BaseModel):
    page_number: int
    page_size: int

class UpsertResenaRequest(BaseModel):
    correo_electronico: str = Field(..., max_length=150, description="Correo del usuario")
    reseña_id: Optional[int] = Field(None, description="ID de la reseña (opcional, para actualizar)")
    id_producto: int = Field(..., description="ID del producto")
    calificacion: int = Field(None, ge=1, le=5, description="Calificación del producto (1-5)")
    comentario: str = Field(None, description="Comentario de la reseña")
    fecha: str = Field(None, description="Fecha de la reseña (opcional) en formato YYYY-MM-DD")

# Nuevo Tamara

class UpdateEstadoPedidoRequest(BaseModel):
    id_pedido: int
    nuevo_estado: str

class UpdateUserInput(BaseModel):
    id: int
    nombre: str
    apellido: str
    correo: str
    contrasena: str
    numero_tel: str
    tipo_usuario: str


class MetodoPago(BaseModel):
    usuario_id: int
    tipo: str
    detalles: str
    principal: bool