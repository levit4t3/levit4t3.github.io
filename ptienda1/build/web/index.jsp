<%-- 
    Document   : index
    Created on : 6 oct 2025, 9:16:57 a.m.
    Author     : kato
--%>

<%@page import="server.Server"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="client.Client"%>
<%@page import="page.Product"%>
<%
    Thread sv = new Thread(new Server());
    sv.start();
    Client socketClient = (Client) session.getAttribute("clienteSocket");
    String error = null;
    List<Product> productos = new ArrayList<>();
    Client.CartSnapshot carritoSnapshot = null;
    try {
        if (socketClient == null) {
            socketClient = new Client();
            session.setAttribute("clienteSocket", socketClient);
        }
        productos = socketClient.catalogo();
        carritoSnapshot = socketClient.verCarrito();
    } catch (Exception ex) {
        error = "No fue posible conectar con el servidor: " + ex.getMessage();
        session.removeAttribute("clienteSocket");
        try {
            if (socketClient != null) {
                socketClient.close();
            }
        } catch (Exception ignored) {}
    }
    Set<String> tipos = new LinkedHashSet<>();
    for (Product p : productos) {
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
        <meta name="description" content="Tienda en línea de componentes electrónicos" />
        <meta name="author" content="Equipo ESCOM" />
        <title>Tienda Electrónica ESCQ</title>
        <!-- Favicon-->
        <link rel="icon" type="image/x-icon" href="assets/favicon.ico" />
        <!-- Bootstrap icons-->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.5.0/font/bootstrap-icons.css" rel="stylesheet" />
        <!-- Core theme CSS (includes Bootstrap)-->
        <link href="css/styles.css" rel="stylesheet" />
    </head>
    <body>
        <!-- Navigation-->
        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <div class="container px-4 px-lg-5">
                <a class="navbar-brand" href="index.jsp">Tienda ESCQ</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
                <div class="collapse navbar-collapse" id="navbarSupportedContent">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0 ms-lg-4">
                        <li class="nav-item"><a class="nav-link active" aria-current="page" href="index.jsp">Inicio</a></li>
                        <li class="nav-item"><a class="nav-link" href="buscar.jsp">Búsqueda</a></li>
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" id="navbarDropdown" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">Categorías</a>
                            <ul class="dropdown-menu" aria-labelledby="navbarDropdown">
                                <li><a class="dropdown-item" href="buscar.jsp">Todas</a></li>
                                <li><hr class="dropdown-divider" /></li>
                                <% for (String tipo : tipos) { %>
                                    <li><a class="dropdown-item" href="buscar.jsp?tipo=<%= tipo %>"><%= tipo %></a></li>
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
        <!-- Header-->
        <header class="bg-dark py-5">
            <div class="container px-4 px-lg-5 my-5">
                <div class="row align-items-center">
                    <div class="col-lg-8 text-white">
                        <h1 class="display-5 fw-bolder">Componentes electrónicos a un clic</h1>
                        <p class="lead fw-normal text-white-50 mb-0">Busca, compara y arma tu carrito en segundos. Todos los pedidos incluyen ticket digital.</p>
                    </div>
                    <div class="col-lg-4 mt-4 mt-lg-0">
                        <form class="card card-body" method="get" action="buscar.jsp">
                            <h5 class="text-dark mb-3">Encuentra rápido lo que necesitas</h5>
                            <div class="input-group">
                                <input type="search" class="form-control" name="q" placeholder="Nombre o marca" required />
                                <button class="btn btn-primary" type="submit">Buscar</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </header>
        <main class="py-5">
            <div class="container px-4 px-lg-5">
                <% if (error != null) { %>
                    <div class="alert alert-danger" role="alert">
                        <%= error %>
                    </div>
                <% } %>
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2 class="fw-bolder">Catálogo disponible</h2>
                    <div>
                        <span class="text-muted">Elementos en catálogo: <strong><%= productos.size() %></strong></span>
                    </div>
                </div>
                <div class="row gx-4 gx-lg-5 row-cols-1 row-cols-md-2 row-cols-xl-3 justify-content-center">
                    <% for (Product producto : productos) { %>
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
                    <% if (productos.isEmpty()) { %>
                        <div class="col-12">
                            <div class="alert alert-info text-center">No hay productos disponibles en este momento.</div>
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

