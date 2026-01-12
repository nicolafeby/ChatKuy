module.exports = {
  env: {
    node: true,
    es2021: true
  },
  parserOptions: {
    ecmaVersion: 2021
  },
  extends: ['eslint:recommended'],
  rules: {
    quotes: ['error', 'single'],
    indent: ['error', 2],
    'comma-dangle': 'off',
    'object-curly-spacing': 'off',
    'no-multi-spaces': 'off'
  }
};
