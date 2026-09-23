<?php
declare(strict_types=1);
namespace CifraSanta\Core;

final class Router {
    private array $routes = [];

    public function get(string $pattern, callable $handler): void { $this->add('GET', $pattern, $handler); }
    public function post(string $pattern, callable $handler): void { $this->add('POST', $pattern, $handler); }
    private function add(string $method, string $pattern, callable $handler): void {
        $regex = '#^' . preg_replace('/\{([a-zA-Z]+)\}/', '(?P<$1>[a-zA-Z0-9-]+)', $pattern) . '$#D';
        $this->routes[] = [$method, $regex, $handler];
    }
    public function dispatch(string $method, string $uri): void {
        $path = parse_url($uri, PHP_URL_PATH) ?: '/';
        $base = \base_path();
        if ($base !== '' && str_starts_with($path, $base . '/')) $path = substr($path, strlen($base));
        if ($path !== '/') $path = rtrim($path, '/');
        foreach ($this->routes as [$routeMethod, $regex, $handler]) {
            if ($routeMethod !== $method || !preg_match($regex, $path, $matches)) continue;
            $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
            $handler(...array_values($params));
            return;
        }
        http_response_code(404);
        \render('not-found', ['title' => 'Página não encontrada · Cifra Santa']);
    }
}
