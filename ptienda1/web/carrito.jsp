<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.LinkedHashSet"%>
<%@page import="java.util.Set"%>
<%@page import="client.Client"%>
<%@page import="page.Product"%>
<%
    Client socketClient = (Client) session.getAttribute("clienteSocket");
    String error = null;
    String mensaje = null;
    Client.CartSnapshot carritoSnapshot = null;
    List<Product> catalogo = new ArrayList<>();
    String accion = request.getParameter("accion");
    String productoId = request.getParameter("productoId");
    String cantidadTexto = request.getParameter("cantidad");
    try {
        if (socketClient == null) {
            socketClient = new Client();
            session.setAttribute("clienteSocket", socketClient);
        }
        if ("agregar".equalsIgnoreCase(accion) && productoId != null) {
            int cantidad = cantidadTexto != null ? Integer.parseInt(cantidadTexto) : 1;
            carritoSnapshot = socketClient.agregar(productoId, cantidad);
        } else if ("actualizar".equalsIgnoreCase(accion) && productoId != null) {
            int cantidad = cantidadTexto != null ? Integer.parseInt(cantidadTexto) : 1;
            carritoSnapshot = socketClient.actualizar(productoId, cantidad);
        } else if ("eliminar".equalsIgnoreCase(accion) && productoId != null) {
            carritoSnapshot = socketClient.eliminar(productoId);
        } else if ("limpiar".equalsIgnoreCase(accion)) {
            carritoSnapshot = socketClient.limpiar();
        } else {
            carritoSnapshot = socketClient.verCarrito();
        }
        catalogo = socketClient.catalogo();
    } catch (NumberFormatException nfe) {
        error = "La cantidad ingresada no es válida.";
        try {
            if (socketClient != null) {
                carritoSnapshot = socketClient.verCarrito();
                catalogo = socketClient.catalogo();
            }
        } catch (Exception ignored) {}
    } catch (Exception ex) {
        error = "Ocurrió un problema al comunicar con el servidor: " + ex.getMessage();
        session.removeAttribute("clienteSocket");
        try {
            if (socketClient != null) {
                socketClient.close();
            }
        } catch (Exception ignored) {}
    }
    if (carritoSnapshot != null) {
        if (carritoSnapshot.isOk()) {
            mensaje = carritoSnapshot.getMensaje();
        } else if (error == null) {
            error = carritoSnapshot.getMensaje();
        }
    }
    Set<String> tipos = new LinkedHashSet<>();
    for (Product p : catalogo) {
        tipos.add(p.getTipo());
    }
    int totalCarrito = 0;
    if (carritoSnapshot != null && carritoSnapshot.isOk()) {
        for (Client.CartItem item : carritoSnapshot.getItems()) {
            totalCarrito += item.getCantidad();
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
        <title>Carrito de compras - Tienda ESCQ</title>
        <link rel="icon" type="image/x-icon" href="assets/favicon.ico" />
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.5.0/font/bootstrap-icons.css" rel="stylesheet" />
        <link href="css/styles.css" rel="stylesheet" />
    </head>
    <body>
        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <div class="container px-4 px-lg-5">
                <a class="navbar-brand" href="index.jsp">Tienda ESCQ</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
                <div class="collapse navbar-collapse" id="navbarSupportedContent">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0 ms-lg-4">
                        <li class="nav-item"><a class="nav-link" href="index.jsp">Inicio</a></li>
                        <li class="nav-item"><a class="nav-link" href="buscar.jsp">Búsqueda</a></li>
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" id="navbarDropdown" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">Categorías</a>
                            <ul class="dropdown-menu" aria-labelledby="navbarDropdown">
                                <li><a class="dropdown-item" href="buscar.jsp">Todas</a></li>
                                <li><hr class="dropdown-divider" /></li>
                                <% for (String catalogoTipo : tipos) { %>
                                    <li><a class="dropdown-item" href="buscar.jsp?tipo=<%= catalogoTipo %>"><%= catalogoTipo %></a></li>
                                <% } %>
                            </ul>
                        </li>
                    </ul>
                    <form class="d-flex me-3" method="get" action="buscar.jsp">
                        <input class="form-control me-2" type="search" placeholder="Buscar producto" name="q" />
                        <button class="btn btn-outline-success" type="submit">Buscar</button>
                    </form>
                    <a class="btn btn-dark" href="carrito.jsp">
                        <i class="bi-cart-fill me-1"></i>
                        Carrito
                        <span class="badge bg-light text-dark ms-1 rounded-pill"><%= totalCarrito %></span>
                    </a>
                </div>
            </div>
        </nav>
        <header class="bg-secondary py-5 text-white">
            <div class="container px-4 px-lg-5">
                <h1 class="fw-bolder">Tu carrito de compras</h1>
                <p class="lead text-white-50">Revisa las cantidades, elimina artículos o procede a la compra.</p>
            </div>
        </header>
        <main class="py-5">
            <div class="container px-4 px-lg-5">
                <% if (mensaje != null && error == null) { %>
                    <div class="alert alert-success" role="alert">
                        <%= mensaje %>
                    </div>
                <% } %>
                <% if (error != null) { %>
                    <div class="alert alert-danger" role="alert">
                        <%= error %>
                    </div>
                <% } %>
                <div class="card">
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Producto</th>
                                        <th class="text-center">Cantidad</th>
                                        <th class="text-end">Precio unitario</th>
                                        <th class="text-end">Subtotal</th>
                                        <th></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (carritoSnapshot != null && carritoSnapshot.isOk() && !carritoSnapshot.getItems().isEmpty()) { %>
                                        <% for (Client.CartItem item : carritoSnapshot.getItems()) { %>
                                            <tr>
                                                <td>
                                                    <strong><%= item.getNombre() %></strong><br />
                                                    <small>ID: <%= item.getProductoId() %></small>
                                                </td>
                                                <td class="text-center">
                                                    <form class="d-flex justify-content-center" method="post" action="carrito.jsp">
                                                        <input type="hidden" name="accion" value="actualizar" />
                                                        <input type="hidden" name="productoId" value="<%= item.getProductoId() %>" />
                                                        <input type="number" class="form-control form-control-sm w-50" name="cantidad" min="0" value="<%= item.getCantidad() %>" />
                                                        <button class="btn btn-link btn-sm" type="submit" title="Actualizar"><i class="bi bi-arrow-repeat"></i></button>
                                                    </form>
                                                </td>
                                                <td class="text-end">$<%= String.format(java.util.Locale.US, "%.2f", item.getPrecio()) %></td>
                                                <td class="text-end">$<%= String.format(java.util.Locale.US, "%.2f", item.getSubtotal()) %></td>
                                                <td class="text-end">
                                                    <form method="post" action="carrito.jsp">
                                                        <input type="hidden" name="accion" value="eliminar" />
                                                        <input type="hidden" name="productoId" value="<%= item.getProductoId() %>" />
                                                        <button class="btn btn-outline-danger btn-sm" type="submit"><i class="bi bi-trash"></i></button>
                                                    </form>
                                                </td>
                                            </tr>
                                        <% } %>
                                    <% } else { %>
                                        <tr>
                                            <td colspan="5" class="text-center text-muted py-4">Tu carrito está vacío.</td>
                                        </tr>
                                    <% } %>
                                </tbody>
                                <% if (carritoSnapshot != null && carritoSnapshot.isOk() && !carritoSnapshot.getItems().isEmpty()) { %>
                                    <tfoot>
                                        <tr>
                                            <td colspan="3" class="text-end"><strong>Total:</strong></td>
                                            <td class="text-end"><strong>$<%= String.format(java.util.Locale.US, "%.2f", carritoSnapshot.getTotal()) %></strong></td>
                                            <td></td>
                                        </tr>
                                    </tfoot>
                                <% } %>
                            </table>
                        </div>
                        <div class="d-flex flex-wrap justify-content-between">
                            <div>
                                <a class="btn btn-outline-secondary" href="index.jsp"><i class="bi bi-arrow-left me-1"></i> Seguir comprando</a>
                                <% if (carritoSnapshot != null && carritoSnapshot.isOk() && !carritoSnapshot.getItems().isEmpty()) { %>
                                    <form class="d-inline" method="post" action="carrito.jsp">
                                        <input type="hidden" name="accion" value="limpiar" />
                                        <button class="btn btn-outline-danger" type="submit"><i class="bi bi-x-circle me-1"></i> Vaciar carrito</button>
                                    </form>
                                <% } %>
                            </div>
                            <% if (carritoSnapshot != null && carritoSnapshot.isOk() && !carritoSnapshot.getItems().isEmpty()) { %>
                                <div>
                                    <a class="btn btn-primary" href="checkout.jsp"><i class="bi bi-credit-card me-1"></i> Finalizar compra</a>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </main>
        <footer class="py-5 bg-dark">
            <div class="container"><p class="m-0 text-center text-white">&copy; Tienda ESCQ 2025</p></div>
        </footer>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
        <script src="js/scripts.js"></script>
    </body>
</html>
