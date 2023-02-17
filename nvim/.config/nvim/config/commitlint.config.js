// commitlint.config.js

const Config = {
    extends: ["@commitlint/config-conventional"],
    formatter: "commitlint-format-json",
    rules: {
        // Disable for now, maybe look into ignoring only when body is a comment?
        "body-leading-blank": [0, "always", "."],
    },
    ignores: [(commit) => commit.split("\n").every(l => (l === "") || (l.startsWith("#")))],
};

module.exports = Config;
