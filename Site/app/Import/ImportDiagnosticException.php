<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;
use Throwable;

/**
 * Falha da importação com o diagnóstico técnico real (etapa, status HTTP, redirects, tempo...).
 * A mensagem descreve o erro de verdade; o painel admin mostra também $diagnostico.
 */
final class ImportDiagnosticException extends RuntimeException {
    public function __construct(string $message,int $code,public readonly array $diagnostico,?Throwable $previous=null) {
        parent::__construct($message,$code,$previous);
    }
}
