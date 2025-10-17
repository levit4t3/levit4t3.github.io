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
    List<Product> catalogo = new ArrayList<>();
    List<Product> resultados = new ArrayList<>();
    Client.CartSnapshot carritoSnapshot = null;
    String query = request.getParameter("q");
    String tipo = request.getParameter("tipo");
    String titulo = "Catálogo completo";
    String subtitulo = "Explora todos nuestros productos disponibles.";
    try {
        if (socketClient == null) {
            socketClient = new Client();
            session.setAttribute("clienteSocket", socketClient);
        }
        catalogo = socketClient.catalogo();
        carritoSnapshot = socketClient.verCarrito();
        if (tipo != null && !tipo.trim().isEmpty()) {
            resultados = socketClient.listarPorTipo(tipo.trim());
            titulo = "Productos del tipo: " + tipo;
            subtitulo = "Mostrando artículos pertenecientes a la categoría seleccionada.";
        } else if (query != null && !query.trim().isEmpty()) {
            resultados = socketClient.buscar(query.trim());
            titulo = "Búsqueda: " + query;
            subtitulo = "Resultados que coinciden con tu consulta por nombre o marca.";
        } else {
            resultados = new ArrayList<>(catalogo);
        }
    } catch (Exception ex) {
        error = "No fue posible recuperar los productos: " + ex.getMessage();
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
        <title>Buscar productos - Tienda ESCQ</title>
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
                        <li class="nav-item"><a class="nav-link active" aria-current="page" href="buscar.jsp">Búsqueda</a></li>
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
                        <input class="form-control me-2" type="search" placeholder="Buscar producto" name="q" value="<%= query != null ? query : "" %>" />
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
        <header class="bg-primary py-5 text-white">
            <div class="container px-4 px-lg-5">
                <h1 class="fw-bolder"><%= titulo %></h1>
                <p class="lead text-white-50"><%= subtitulo %></p>
                <a class="btn btn-light" href="index.jsp"><i class="bi-arrow-left-circle me-1"></i> Volver al inicio</a>
            </div>
        </header>
        <main class="py-5">
            <div class="container px-4 px-lg-5">
                <% if (error != null) { %>
                    <div class="alert alert-danger" role="alert">
                        <%= error %>
                    </div>
                <% } %>
                <div class="row gx-4 gx-lg-5 row-cols-1 row-cols-md-2 row-cols-xl-3 justify-content-center">
                    <% for (Product producto : resultados) { %>
                        <div class="col mb-5">
                            <div class="card h-100">
                                <img class="card-img-top" src="<%= producto.getImagen() != null ? producto.getImagen() : "https://dummyimage.com/450x300/dee2e6/6c757d" %>" alt="<%= producto.getNombre() %>" />
                                <div class="card-body p-4">
                                    <div class="small text-muted mb-1"><i class="bi-tag me-1"></i> <%= producto.getTipo() %> &middot; <%= producto.getMarca() %></div>
                                    <h5 class="fw-bolder"><%= producto.getNombre() %></h5>
                                    <p class="mb-2">$<%= String.format(java.util.Locale.US, "%.2f", producto.getPrecio()) %> MXN</p>
                                    <span class="badge bg-secondary">Disponible: <%= producto.getStock() %></span>
                                </div>
                                <div class="card-footer p-4 pt-0 border-top-0 bg-transparent">
                                    <form class="text-center" action="carrito.jsp" method="post">
                                        <input type="hidden" name="accion" value="agregar" />
                                        <input type="hidden" name="productoId" value="<%= producto.getId() %>" />
                                        <div class="input-group mb-2">
                                            <span class="input-group-text">Cantidad</span>
                                            <input type="number" class="form-control" name="cantidad" min="1" max="<%= Math.max(1, producto.getStock()) %>" value="1" />
                                        </div>
                                        <button class="btn btn-outline-dark mt-auto" type="submit" <%= producto.getStock() <= 0 ? "disabled" : "" %>>
                                            <i class="bi bi-cart-plus me-1"></i> Agregar al carrito
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    <% } %>
                    <% if (resultados.isEmpty() && error == null) { %>
                        <div class="col-12">
                            <div class="alert alert-info text-center">No encontramos coincidencias para tu búsqueda.</div>
                        </div>
                    <% } %>
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
