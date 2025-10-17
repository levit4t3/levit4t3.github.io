package client;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */


/**
 *
 * @author kato
 */
/*package whatever //do not write package name here */
import java.io.*;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.*;
import page.Product;

public class Client implements Closeable {

	public static class CartItem {
		private final String productoId;
		private final String nombre;
		private final int cantidad;
		private final double precio;
		private final double subtotal;

		public CartItem(String productoId, String nombre, int cantidad, double precio, double subtotal) {
			this.productoId = productoId;
			this.nombre = nombre;
			this.cantidad = cantidad;
			this.precio = precio;
			this.subtotal = subtotal;
		}

		public String getProductoId() {
			return productoId;
		}

		public String getNombre() {
			return nombre;
		}

		public int getCantidad() {
			return cantidad;
		}

		public double getPrecio() {
			return precio;
		}

		public double getSubtotal() {
			return subtotal;
		}
	}

	public static class CartSnapshot {
		private final boolean ok;
		private final String mensaje;
		private final List<CartItem> items;
		private final double total;

		public CartSnapshot(boolean ok, String mensaje, List<CartItem> items, double total) {
			this.ok = ok;
			this.mensaje = mensaje;
			this.items = Collections.unmodifiableList(new ArrayList<>(items));
			this.total = total;
		}

		public boolean isOk() {
			return ok;
		}

		public String getMensaje() {
			return mensaje;
		}

		public List<CartItem> getItems() {
			return items;
		}

		public double getTotal() {
			return total;
		}
	}

	public static class TicketSnapshot {
		private final boolean ok;
		private final String folio;
		private final String fecha;
		private final double total;
		private final List<CartItem> items;
		private final String mensaje;

		public TicketSnapshot(boolean ok, String folio, String fecha, double total, List<CartItem> items, String mensaje) {
			this.ok = ok;
			this.folio = folio;
			this.fecha = fecha;
			this.total = total;
			this.items = Collections.unmodifiableList(new ArrayList<>(items));
			this.mensaje = mensaje;
		}

		public boolean isOk() {
			return ok;
		}

		public String getFolio() {
			return folio;
		}

		public String getFecha() {
			return fecha;
		}

		public double getTotal() {
			return total;
		}

		public List<CartItem> getItems() {
			return items;
		}

		public String getMensaje() {
			return mensaje;
		}
	}

	private final String host;
	private final int puerto;
	private Socket socket;
	private BufferedReader entrada;
	private PrintWriter salida;
	private List<Product> catalogoCache = new ArrayList<>();

	public Client(String host, int puerto) throws IOException {
		this.host = host;
		this.puerto = puerto;
		conectar();
	}

	public Client() throws IOException {
		this("localhost", 8089);
	}

	private void conectar() throws IOException {
		this.socket = new Socket(host, puerto);
	this.entrada = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
	this.salida = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);
		this.catalogoCache = leerCatalogo();
	}

	public synchronized List<Product> catalogo() throws IOException {
		enviar("CATALOGO");
		this.catalogoCache = leerCatalogo();
		return new ArrayList<>(catalogoCache);
	}

	public synchronized List<Product> buscar(String texto) throws IOException {
		enviar(String.format(Locale.ROOT, "BUSCAR|%s", texto == null ? "" : texto.trim()));
		return leerCatalogo();
	}

	public synchronized List<Product> listarPorTipo(String tipo) throws IOException {
		enviar(String.format(Locale.ROOT, "LISTAR_TIPO|%s", tipo == null ? "" : tipo.trim()));
		return leerCatalogo();
	}

	public synchronized CartSnapshot agregar(String productoId, int cantidad) throws IOException {
		enviar(String.format(Locale.ROOT, "AGREGAR|%s|%d", productoId, cantidad));
		return leerCarrito();
	}

	public synchronized CartSnapshot actualizar(String productoId, int cantidad) throws IOException {
		enviar(String.format(Locale.ROOT, "ACTUALIZAR|%s|%d", productoId, cantidad));
		return leerCarrito();
	}

	public synchronized CartSnapshot eliminar(String productoId) throws IOException {
		enviar(String.format(Locale.ROOT, "ELIMINAR|%s", productoId));
		return leerCarrito();
	}

	public synchronized CartSnapshot verCarrito() throws IOException {
		enviar("VER_CARRITO");
		return leerCarrito();
	}

	public synchronized CartSnapshot limpiar() throws IOException {
		enviar("LIMPIAR");
		String linea = leerLinea();
		if (linea == null) {
			return new CartSnapshot(false, "Sin respuesta del servidor", Collections.emptyList(), 0);
		}
		if (linea.startsWith("ACK|")) {
			String[] partes = linea.split("\\|", -1);
			String mensaje = partes.length > 2 ? partes[2] : "Carrito vaciado";
			return new CartSnapshot(true, mensaje, Collections.emptyList(), 0);
		}
		if (linea.startsWith("ERROR|")) {
			return new CartSnapshot(false, extraerMensaje(linea), Collections.emptyList(), 0);
		}
		// Si el servidor envía el estado del carrito
		return procesarCarritoDesdeLinea(linea);
	}

	public synchronized TicketSnapshot finalizarCompra() throws IOException {
		enviar("FINALIZAR");
		String linea = leerLinea();
		if (linea == null) {
			return new TicketSnapshot(false, null, null, 0, Collections.emptyList(), "Sin respuesta del servidor");
		}
		if (linea.startsWith("ERROR|")) {
			return new TicketSnapshot(false, null, null, 0, Collections.emptyList(), extraerMensaje(linea));
		}
		if (!linea.startsWith("TICKET_INICIO")) {
			return new TicketSnapshot(false, null, null, 0, Collections.emptyList(), "Respuesta inesperada: " + linea);
		}
		String[] inicio = linea.split("\\|", -1);
		String folio = inicio.length > 1 ? inicio[1] : "";
		String fecha = inicio.length > 2 ? inicio[2] : "";
		double total = inicio.length > 3 ? parseDoubleSeguro(inicio[3]) : 0;
		List<CartItem> items = new ArrayList<>();
		while ((linea = leerLinea()) != null && !linea.startsWith("TICKET_FIN")) {
			if (linea.startsWith("LINEA|")) {
				String[] datos = linea.split("\\|", -1);
				if (datos.length >= 6) {
					items.add(new CartItem(
							datos[1],
							datos[2],
							parseEnteroSeguro(datos[3]),
							parseDoubleSeguro(datos[4]),
							parseDoubleSeguro(datos[5])
					));
				}
			}
		}
		String mensaje = (linea != null && linea.contains("|")) ? linea.split("\\|", -1)[1] : "Gracias";
		return new TicketSnapshot(true, folio, fecha, total, items, mensaje);
	}

	private CartSnapshot leerCarrito() throws IOException {
		String linea = leerLinea();
		if (linea == null) {
			return new CartSnapshot(false, "Sin respuesta del servidor", Collections.emptyList(), 0);
		}
		if (linea.startsWith("ERROR|")) {
			return new CartSnapshot(false, extraerMensaje(linea), Collections.emptyList(), 0);
		}
		if (!linea.startsWith("CARRITO_INICIO")) {
			return new CartSnapshot(false, "Respuesta inesperada: " + linea, Collections.emptyList(), 0);
		}
		return procesarCarritoDesdeLinea(linea);
	}

	private CartSnapshot procesarCarritoDesdeLinea(String lineaInicio) throws IOException {
		String[] inicio = lineaInicio.split("\\|", -1);
		String mensaje = inicio.length > 1 ? inicio[1] : "";
		List<CartItem> items = new ArrayList<>();
		String linea;
		while ((linea = leerLinea()) != null && !linea.startsWith("CARRITO_FIN")) {
			if (linea.startsWith("ITEM|")) {
				String[] datos = linea.split("\\|", -1);
				if (datos.length >= 6) {
					items.add(new CartItem(
							datos[1],
							datos[2],
							parseEnteroSeguro(datos[3]),
							parseDoubleSeguro(datos[4]),
							parseDoubleSeguro(datos[5])
					));
				}
			}
		}
		double total = 0;
		if (linea != null) {
			String[] fin = linea.split("\\|", -1);
			if (fin.length > 1) {
				total = parseDoubleSeguro(fin[1]);
			}
		}
		return new CartSnapshot(true, mensaje, items, total);
	}

	private List<Product> leerCatalogo() throws IOException {
		List<Product> productos = new ArrayList<>();
		String linea;
		while ((linea = leerLinea()) != null) {
			if (linea.startsWith("CATALOGO_INICIO")) {
				continue;
			}
			if (linea.startsWith("CATALOGO_FIN")) {
				break;
			}
			if (linea.startsWith("ERROR|")) {
				throw new IOException(extraerMensaje(linea));
			}
			if (linea.startsWith("PRODUCTO|")) {
				String data = linea.substring("PRODUCTO|".length());
				productos.add(Product.fromDataString(data));
			}
		}
		return productos;
	}

	private void enviar(String comando) {
		salida.println(comando);
	}

	private String leerLinea() throws IOException {
		return entrada.readLine();
	}

	private String extraerMensaje(String linea) {
		String[] partes = linea.split("\\|", -1);
		return partes.length > 1 ? partes[1] : linea;
	}

	private int parseEnteroSeguro(String valor) {
		try {
			return Integer.parseInt(valor);
		} catch (NumberFormatException e) {
			return 0;
		}
	}

	private double parseDoubleSeguro(String valor) {
		try {
			return Double.parseDouble(valor);
		} catch (NumberFormatException e) {
			return 0;
		}
	}

	@Override
	public void close() throws IOException {
		if (socket != null && !socket.isClosed()) {
			socket.close();
		}
	}
}

