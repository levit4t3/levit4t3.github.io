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
    Client.CartSnapshot carritoSnapshot = null;
    List<Product> catalogo = new ArrayList<>();
    try {
        if (socketClient == null) {
            socketClient = new Client();
            session.setAttribute("clienteSocket", socketClient);
        }
        carritoSnapshot = socketClient.verCarrito();
        catalogo = socketClient.catalogo();
    } catch (Exception ex) {
        error = "No fue posible obtener el resumen de tu compra: " + ex.getMessage();
        session.removeAttribute("clienteSocket");
        try {
            if (socketClient != null) {
                socketClient.close();
            }
        } catch (Exception ignored) {}
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
        <title>Finalizar compra - Tienda ESCQ</title>
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
                    <a class="btn btn-outline-dark" href="carrito.jsp">
                        <i class="bi-cart-fill me-1"></i>
                        Carrito
                        <span class="badge bg-dark text-white ms-1 rounded-pill"><%= totalCarrito %></span>
                    </a>
                </div>
            </div>
        </nav>
        <header class="bg-success text-white py-5">
            <div class="container px-4 px-lg-5">
                <h1 class="fw-bolder">Confirma tu compra</h1>
                <p class="lead text-white-50">Revisa el resumen y obtén tu ticket en el siguiente paso.</p>
            </div>
        </header>
        <main class="py-5">
            <div class="container px-4 px-lg-5">
                <% if (error != null) { %>
                    <div class="alert alert-danger" role="alert">
                        <%= error %>
                    </div>
                <% } %>
                <div class="card">
                    <div class="card-body">
                        <% if (carritoSnapshot != null && carritoSnapshot.isOk() && !carritoSnapshot.getItems().isEmpty()) { %>
                            <div class="mb-4">
                                <h5>Resumen del pedido</h5>
                                <ul class="list-group list-group-flush">
                                    <% for (Client.CartItem item : carritoSnapshot.getItems()) { %>
                                        <li class="list-group-item d-flex justify-content-between align-items-center">
                                            <div>
                                                <strong><%= item.getNombre() %></strong><br />
                                                <small>Cantidad: <%= item.getCantidad() %></small>
                                            </div>
                                            <span>$<%= String.format(java.util.Locale.US, "%.2f", item.getSubtotal()) %></span>
                                        </li>
                                    <% } %>
                                    <li class="list-group-item d-flex justify-content-between align-items-center">
                                        <strong>Total a pagar</strong>
                                        <span class="fs-5">$<%= String.format(java.util.Locale.US, "%.2f", carritoSnapshot.getTotal()) %></span>
                                    </li>
                                </ul>
                            </div>
                            <form method="post" action="ticket.jsp" class="text-end">
                                <button class="btn btn-primary btn-lg" type="submit"><i class="bi bi-check-circle me-1"></i> Generar ticket</button>
                            </form>
                        <% } else { %>
                            <div class="alert alert-info" role="alert">
                                No hay productos en el carrito. Agrega artículos antes de finalizar la compra.
                            </div>
                            <a class="btn btn-outline-secondary" href="index.jsp"><i class="bi bi-arrow-left me-1"></i> Ir al catálogo</a>
                        <% } %>
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
