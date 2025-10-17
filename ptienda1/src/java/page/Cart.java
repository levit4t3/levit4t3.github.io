package page;

import java.io.Serializable;
import java.util.*;

public class Cart implements Serializable {

	public static class Item implements Serializable {
		private final Product producto;
		private int cantidad;

		public Item(Product producto, int cantidad) {
			this.producto = producto;
			this.cantidad = cantidad;
		}

		public Product getProducto() {
			return producto;
		}

		public int getCantidad() {
			return cantidad;
		}

		public void setCantidad(int cantidad) {
			if (cantidad < 0) {
				throw new IllegalArgumentException("Cantidad negativa");
			}
			this.cantidad = cantidad;
		}

		public double getSubtotal() {
			return producto.getPrecio() * cantidad;
		}
	}

	private final Map<String, Item> items = new LinkedHashMap<>();

	public synchronized void agregar(Product producto, int cantidad) {
		if (cantidad <= 0) {
			throw new IllegalArgumentException("La cantidad debe ser positiva");
		}
		Item existente = items.get(producto.getId());
		if (existente == null) {
			items.put(producto.getId(), new Item(producto, cantidad));
		} else {
			existente.setCantidad(existente.getCantidad() + cantidad);
		}
	}

	public synchronized Item obtener(String productoId) {
		return items.get(productoId);
	}

	public synchronized void actualizarCantidad(String productoId, int cantidad) {
		if (!items.containsKey(productoId)) {
			return;
		}
		if (cantidad <= 0) {
			items.remove(productoId);
		} else {
			items.get(productoId).setCantidad(cantidad);
		}
	}

	public synchronized void eliminar(String productoId) {
		items.remove(productoId);
	}

	public synchronized void limpiar() {
		items.clear();
	}

	public synchronized Collection<Item> getItems() {
		return Collections.unmodifiableCollection(items.values());
	}

	public synchronized double getTotal() {
		return items.values().stream()
				.mapToDouble(Item::getSubtotal)
				.sum();
	}

	public synchronized boolean estaVacio() {
		return items.isEmpty();
	}
}
