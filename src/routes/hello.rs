use axum::{Router, routing::get};

use crate::handlers::hello;

pub fn hello_router() -> Router {
    Router::new()
        .route("/hello", get(hello::hello))
}
