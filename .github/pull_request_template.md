## Resumo

Descreva a mudança e o problema que ela resolve.

## Tipo de mudança

- [ ] Correção de bug
- [ ] Nova funcionalidade
- [ ] Refatoração sem mudança de comportamento
- [ ] Documentação
- [ ] Empacotamento / CI
- [ ] Mudança incompatível (explique abaixo)

## Como foi testado

Descreva os testes automatizados e a verificação manual. Se envolve hardware,
diga quais dispositivos e versões de kernel/driver foram usados.

```sh
flutter analyze
flutter test
```

## Checklist

- [ ] O código segue as camadas e as regras de [`docs/arquitetura.md`](docs/arquitetura.md).
- [ ] `flutter analyze` e `flutter test` passam.
- [ ] Mudanças de comportamento atualizam a documentação e o `CHANGELOG.md`.
- [ ] Não incluí efeitos, fontes, binários ou outros recursos proprietários de terceiros.
- [ ] Não incluí notas locais de engenharia reversa (`docs/re/`, protocolos) no pacote.
- [ ] A versão foi atualizada com `scripts/bump-version.sh` quando o pacote muda.

## Contexto adicional

Issues relacionadas, capturas, medições ou decisões de projeto.
