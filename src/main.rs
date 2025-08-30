use axum::Router;

mod routes;
mod handlers;

use crate::routes::hello;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .merge(hello::hello_router());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
