package page;

import java.io.Serializable;
import java.util.*;

public class Product implements Serializable {

	private final String id;
	private final String nombre;
	private final String marca;
	private final String tipo;
	private final double precio;
	private int stock;
	private final String imagen;

	public Product(String id, String nombre, String marca, String tipo, double precio, int stock, String imagen) {
		this.id = Objects.requireNonNull(id);
		this.nombre = Objects.requireNonNull(nombre);
		this.marca = Objects.requireNonNull(marca);
		this.tipo = Objects.requireNonNull(tipo);
		this.precio = precio;
		this.stock = stock;
		this.imagen = imagen;
	}

	public String getId() {
		return id;
	}

	public String getNombre() {
		return nombre;
	}

	public String getMarca() {
		return marca;
	}

	public String getTipo() {
		return tipo;
	}

	public double getPrecio() {
		return precio;
	}

	public synchronized int getStock() {
		return stock;
	}

	public synchronized boolean reducirStock(int cantidad) {
		if (cantidad <= 0 || cantidad > stock) {
			return false;
		}
		stock -= cantidad;
		return true;
	}

	public synchronized void regresarStock(int cantidad) {
		if (cantidad > 0) {
			stock += cantidad;
		}
	}

	public String getImagen() {
		return imagen;
	}

	public String toDataString() {
		return String.join("|",
				escape(id),
				escape(nombre),
				escape(marca),
				escape(tipo),
				String.valueOf(precio),
				String.valueOf(getStock()),
				imagen == null ? "" : imagen
		);
	}

	public static Product fromDataString(String line) {
		String[] parts = line.split("\\|", -1);
		if (parts.length < 7) {
			throw new IllegalArgumentException("Entrada de producto inválida: " + line);
		}
		return new Product(
				unescape(parts[0]),
				unescape(parts[1]),
				unescape(parts[2]),
				unescape(parts[3]),
				Double.parseDouble(parts[4]),
				Integer.parseInt(parts[5]),
				parts[6].isEmpty() ? null : parts[6]
		);
	}

	private static String escape(String value) {
		return value.replace("|", "\\|");
	}

	private static String unescape(String value) {
		return value.replace("\\|", "|");
	}

	public static List<Product> catalogoInicial() {
		List<Product> productos = new ArrayList<>();
		productos.add(new Product("P001", "Fuente 12V 5A", "ElectrónicaMX", "Fuente", 320.0, 10, "img/12V5A_120V — TRANSFORMADOR 12V 5AMP,ENTRADA 120VCA.jpg"));
		productos.add(new Product("P002", "Diodo Rectificador 5A", "ON Semiconductor", "Diodo", 18.5, 30, "img/AR0185-SF56-Diodo-Rectificador-5A-400-V-1.jpg"));
		productos.add(new Product("P003", "Capacitor Cerámico 18pF", "Yageo", "Capacitor", 2.3, 120, "img/cc-18-100v-capacitor-ceramico-18pf.png"));
		productos.add(new Product("P004", "Capacitores Electrolíticos Kit", "Dahua", "Capacitor", 95.0, 25, "img/electroliticos.jpg"));
		productos.add(new Product("P005", "Arduino Uno", "Arduino", "Microcontrolador", 650.0, 15, "img/159694-d.jpg"));
		productos.add(new Product("P006", "Raspberry Pi 4", "Raspberry", "Computadora", 1499.0, 8, "img/61cbjhBLaXL._UF894,1000_QL80_.jpg"));
		productos.add(new Product("P007", "Multímetro Digital", "Fluke", "Herramienta", 880.0, 12, "img/51t10L7efuL.jpg"));
		productos.add(new Product("P008", "Juego de Protoboards", "Elegoo", "Accesorio", 240.0, 20, "img/61y6WSlFJ-L._UF1000,1000_QL80_.jpg"));
		productos.add(new Product("P009", "Kit Sensores", "Keyestudio", "Accesorio", 520.0, 18, "img/61ZedXw77LL._UF894,1000_QL80_.jpg"));
		productos.add(new Product("P010", "Fuente 12V 2A", "Sterem", "Fuente", 190.0, 22, "img/518GKwV41pL.jpg"));
		return Collections.unmodifiableList(productos);
	}
}
