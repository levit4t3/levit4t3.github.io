package page;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class Ticket implements Serializable {

	public static class Linea implements Serializable {
		private final String productoId;
		private final String descripcion;
		private final int cantidad;
		private final double precioUnitario;

		public Linea(String productoId, String descripcion, int cantidad, double precioUnitario) {
			this.productoId = productoId;
			this.descripcion = descripcion;
			this.cantidad = cantidad;
			this.precioUnitario = precioUnitario;
		}

		public String getProductoId() {
			return productoId;
		}

		public String getDescripcion() {
			return descripcion;
		}

		public int getCantidad() {
			return cantidad;
		}

		public double getPrecioUnitario() {
			return precioUnitario;
		}

		public double getSubtotal() {
			return precioUnitario * cantidad;
		}
	}

	private final String folio;
	private final LocalDateTime fecha;
	private final List<Linea> lineas;
	private final double total;

	public Ticket(List<Linea> lineas) {
		this(UUID.randomUUID().toString().substring(0, 8).toUpperCase(), LocalDateTime.now(), lineas);
	}

	public Ticket(String folio, LocalDateTime fecha, List<Linea> lineas) {
		this.folio = folio;
		this.fecha = fecha;
		this.lineas = Collections.unmodifiableList(new ArrayList<>(lineas));
		this.total = this.lineas.stream().mapToDouble(Linea::getSubtotal).sum();
	}

	public String getFolio() {
		return folio;
	}

	public LocalDateTime getFecha() {
		return fecha;
	}

	public List<Linea> getLineas() {
		return lineas;
	}

	public double getTotal() {
		return total;
	}

	public String aTextoPlano() {
		StringBuilder sb = new StringBuilder();
		sb.append("Ticket ").append(folio).append('\n');
		sb.append("Fecha: ").append(fecha.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))).append('\n');
		sb.append("--------------------------------------\n");
		for (Linea linea : lineas) {
			sb.append(linea.getDescripcion())
					.append(" x")
					.append(linea.getCantidad())
					.append(" -> $")
					.append(String.format("%.2f", linea.getSubtotal()))
					.append('\n');
		}
		sb.append("--------------------------------------\n");
		sb.append("Total: $").append(String.format("%.2f", total)).append('\n');
		return sb.toString();
	}
}
