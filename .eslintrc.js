module.exports = {
  root: true,
  env: { es2022: true, node: true },
  ignorePatterns: [
    "dist/**","build/**","coverage/**","node_modules/**",
    "**/*.config.*","**/jest.config.*"
  ],
  overrides: [
    {
      files: ["**/*.ts","**/*.tsx"],
      parser: "@typescript-eslint/parser",
      parserOptions: { ecmaVersion: 2022, sourceType: "module" },
      plugins: ["@typescript-eslint"],
      extends: ["plugin:@typescript-eslint/recommended","prettier"],
      rules:{ "@typescript-eslint/no-unused-vars":[ "error",{ "argsIgnorePattern":"^_", "varsIgnorePattern":"^_", "caughtErrorsIgnorePattern":"^_" } ],

        "@typescript-eslint/no-unused-expressions": "off"
       }
    },
    {
      files: ["**/*.js"],
      parserOptions: { ecmaVersion: 2022, sourceType: "module" }
    }
  ],
  rules: {
    "no-unused-expressions": ["error", {
      allowShortCircuit: true, allowTernary: true, allowTaggedTemplates: true
    }]
  }
};
