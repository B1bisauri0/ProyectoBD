class Pedido {
  final String nombreUsuario;
  final int pedidoID;
  final String fechaPedido;
  final String estado;
  final double precioTotal;
  final String direccion;
  final String detallesMetodo;

  // Constructor
  Pedido({
    required this.nombreUsuario,
    required this.pedidoID,
    required this.fechaPedido,
    required this.estado,
    required this.precioTotal,
    required this.direccion,
    required this.detallesMetodo,
  });

  // Método para crear un objeto Pedido desde un mapa (deserialización)
  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      nombreUsuario: json['NombreUsuario'],
      pedidoID: json['PedidoID'],
      fechaPedido: json['Fecha_Pedido'],
      estado: json['Estado'],
      precioTotal: json['PrecioTotal'].toDouble(),
      direccion: json['Direccion'],
      detallesMetodo: json['DetallesMetodo'],
    );
  }

  // Método para convertir el objeto Pedido en un mapa (serialización)
  Map<String, dynamic> toJson() {
    return {
      'NombreUsuario': nombreUsuario,
      'PedidoID': pedidoID,
      'Fecha_Pedido': fechaPedido,
      'Estado': estado,
      'PrecioTotal': precioTotal,
      'Direccion': direccion,
      'DetallesMetodo': detallesMetodo,
    };
  }
}
