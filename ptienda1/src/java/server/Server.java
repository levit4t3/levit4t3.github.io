package server;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author kato
 */
/*package whatever //do not write package name here */
import page.Ticket;
import page.Cart;
import page.Product;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class Server implements Runnable{

    private final Map<String, Product> inventario = new ConcurrentHashMap<>();

    public Server() {
        for (Product base : Product.catalogoInicial()) {
            inventario.put(base.getId(), new Product(
                    base.getId(),
                    base.getNombre(),
                    base.getMarca(),
                    base.getTipo(),
                    base.getPrecio(),
                    base.getStock(),
                    base.getImagen()
            ));
        }
    }

    public void iniciar(int puerto) throws IOException {
        try (ServerSocket serverSocket = new ServerSocket(puerto)) {
            System.out.println("Servidor escuchando en el puerto " + puerto);
            while (true) {
                Socket socket = serverSocket.accept();
                Thread hilo = new Thread(() -> manejarCliente(socket));
                hilo.setDaemon(true);
                hilo.start();
            }
        }
    }

    private void manejarCliente(Socket socket) {
        System.out.println("Cliente conectado: " + socket.getRemoteSocketAddress());
        try (Socket autoClose = socket;
             BufferedReader entrada = new BufferedReader(new InputStreamReader(socket.getInputStream(), "UTF-8"));
             PrintWriter salida = new PrintWriter(socket.getOutputStream(), true)) {

            enviarCatalogoCompleto(salida);
            Cart carrito = new Cart();
            String linea;
            while ((linea = entrada.readLine()) != null) {
                linea = linea.trim();
                if (linea.isEmpty()) {
                    continue;
                }
                procesarComando(linea, carrito, salida);
            }
        } catch (IOException e) {
            System.err.println("Error con cliente: " + e.getMessage());
        } finally {
            System.out.println("Cliente desconectado");
        }
    }

    private void enviarCatalogoCompleto(PrintWriter salida) {
        salida.println("CATALOGO_INICIO");
        inventario.values().forEach(p -> salida.println("PRODUCTO|" + p.toDataString()));
        salida.println("CATALOGO_FIN");
    }

    private void procesarComando(String linea, Cart carrito, PrintWriter salida) {
        String[] partes = linea.split("\\|", -1);
        String comando = partes[0].toUpperCase(Locale.ROOT);
        switch (comando) {
            case "PING":
                salida.println("ACK|OK|PONG");
                break;
            case "CATALOGO":
                enviarCatalogoCompleto(salida);
                break;
            case "LISTAR_TIPO":
                if (partes.length < 2) {
                    salida.println("ERROR|Tipo no proporcionado");
                } else {
                    enviarCatalogoFiltrado(salida, p -> p.getTipo().equalsIgnoreCase(partes[1]));
                }
                break;
            case "BUSCAR":
                if (partes.length < 2) {
                    salida.println("ERROR|Texto de búsqueda vacío");
                } else {
                    String texto = partes[1].toLowerCase(Locale.ROOT);
                    enviarCatalogoFiltrado(salida, p -> p.getNombre().toLowerCase(Locale.ROOT).contains(texto)
                            || p.getMarca().toLowerCase(Locale.ROOT).contains(texto));
                }
                break;
            case "AGREGAR":
                if (partes.length < 3) {
                    salida.println("ERROR|Datos insuficientes");
                    break;
                }
                manejarAgregar(partes[1], partes[2], carrito, salida);
                break;
            case "ACTUALIZAR":
                if (partes.length < 3) {
                    salida.println("ERROR|Datos insuficientes");
                    break;
                }
                manejarActualizar(partes[1], partes[2], carrito, salida);
                break;
            case "ELIMINAR":
                if (partes.length < 2) {
                    salida.println("ERROR|Datos insuficientes");
                    break;
                }
                manejarEliminar(partes[1], carrito, salida);
                break;
            case "VER_CARRITO":
                enviarCarrito(carrito, "Estado actual del carrito", salida);
                break;
            case "LIMPIAR":
                manejarLimpiar(carrito, salida);
                break;
            case "FINALIZAR":
                manejarFinalizar(carrito, salida);
                break;
            default:
                salida.println("ERROR|Comando no reconocido");
        }
    }

    private void enviarCatalogoFiltrado(PrintWriter salida, java.util.function.Predicate<Product> filtro) {
        salida.println("CATALOGO_INICIO");
        inventario.values().stream().filter(filtro).forEach(p -> salida.println("PRODUCTO|" + p.toDataString()));
        salida.println("CATALOGO_FIN");
    }

    private void manejarAgregar(String productoId, String cantidadTexto, Cart carrito, PrintWriter salida) {
        Product producto = inventario.get(productoId);
        if (producto == null) {
            salida.println("ERROR|Producto no encontrado");
            return;
        }
        int cantidad;
        try {
            cantidad = Integer.parseInt(cantidadTexto);
        } catch (NumberFormatException ex) {
            salida.println("ERROR|Cantidad inválida");
            return;
        }
        if (cantidad <= 0) {
            salida.println("ERROR|La cantidad debe ser mayor a cero");
            return;
        }
        synchronized (producto) {
            if (!producto.reducirStock(cantidad)) {
                salida.println("ERROR|Sin stock suficiente");
                return;
            }
        }
        carrito.agregar(producto, cantidad);
        enviarCarrito(carrito, "Producto agregado", salida);
    }

    private void manejarActualizar(String productoId, String cantidadTexto, Cart carrito, PrintWriter salida) {
        Product producto = inventario.get(productoId);
        if (producto == null) {
            salida.println("ERROR|Producto no encontrado");
            return;
        }
        int cantidad;
        try {
            cantidad = Integer.parseInt(cantidadTexto);
        } catch (NumberFormatException ex) {
            salida.println("ERROR|Cantidad inválida");
            return;
        }
        Cart.Item itemActual = carrito.obtener(productoId);
        int anterior = itemActual == null ? 0 : itemActual.getCantidad();
        int diferencia = cantidad - anterior;
        if (diferencia > 0) {
            synchronized (producto) {
                if (!producto.reducirStock(diferencia)) {
                    salida.println("ERROR|Sin stock suficiente");
                    return;
                }
            }
        } else if (diferencia < 0) {
            producto.regresarStock(-diferencia);
        }
        if (cantidad <= 0) {
            carrito.eliminar(productoId);
        } else {
            if (itemActual == null) {
                carrito.agregar(producto, cantidad);
            } else {
                carrito.actualizarCantidad(productoId, cantidad);
            }
        }
        enviarCarrito(carrito, "Carrito actualizado", salida);
    }

    private void manejarEliminar(String productoId, Cart carrito, PrintWriter salida) {
        Cart.Item item = carrito.obtener(productoId);
        if (item == null) {
            salida.println("ERROR|El producto no está en el carrito");
            return;
        }
        int cantidad = item.getCantidad();
        carrito.eliminar(productoId);
        Product producto = inventario.get(productoId);
        if (producto != null) {
            producto.regresarStock(cantidad);
        }
        enviarCarrito(carrito, "Producto eliminado", salida);
    }

    private void manejarLimpiar(Cart carrito, PrintWriter salida) {
        carrito.getItems().forEach(item -> {
            Product producto = inventario.get(item.getProducto().getId());
            if (producto != null) {
                producto.regresarStock(item.getCantidad());
            }
        });
        carrito.limpiar();
        salida.println("ACK|OK|Carrito vaciado");
    }

    private void manejarFinalizar(Cart carrito, PrintWriter salida) {
        if (carrito.estaVacio()) {
            salida.println("ERROR|El carrito está vacío");
            return;
        }
        List<Ticket.Linea> lineas = new ArrayList<>();
        carrito.getItems().forEach(item -> lineas.add(new Ticket.Linea(
                item.getProducto().getId(),
                item.getProducto().getNombre(),
                item.getCantidad(),
                item.getProducto().getPrecio()
        )));
        Ticket ticket = new Ticket(lineas);
        carrito.limpiar();
        enviarTicket(ticket, salida);
    }

    private void enviarCarrito(Cart carrito, String mensaje, PrintWriter salida) {
        salida.println("CARRITO_INICIO|" + mensaje);
        carrito.getItems().forEach(item -> salida.println(String.format(Locale.ROOT,
                "ITEM|%s|%s|%d|%.2f|%.2f",
                item.getProducto().getId(),
                item.getProducto().getNombre(),
                item.getCantidad(),
                item.getProducto().getPrecio(),
                item.getSubtotal())));
        salida.println(String.format(Locale.ROOT, "CARRITO_FIN|%.2f", carrito.getTotal()));
    }

    private void enviarTicket(Ticket ticket, PrintWriter salida) {
        salida.println(String.format(Locale.ROOT,
                "TICKET_INICIO|%s|%s|%.2f",
                ticket.getFolio(),
                ticket.getFecha(),
                ticket.getTotal()));
        ticket.getLineas().forEach(linea -> salida.println(String.format(Locale.ROOT,
                "LINEA|%s|%s|%d|%.2f|%.2f",
                linea.getProductoId(),
                linea.getDescripcion(),
                linea.getCantidad(),
                linea.getPrecioUnitario(),
                linea.getSubtotal())));
        salida.println("TICKET_FIN|Gracias por su compra");
    }

    public static void main(String[] args) {
        int puerto = 8089;
        if (args.length > 0) {
            try {
                puerto = Integer.parseInt(args[0]);
            } catch (NumberFormatException ignored) {
            }
        }
        Server servidor = new Server();
        try {
            servidor.iniciar(puerto);
        } catch (IOException e) {
            System.err.println("No se pudo iniciar el servidor: " + e.getMessage());
        }
    }

    @Override
    public void run() {
        throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
    }
}