// White-label: clean Brazilian Portuguese home page for the admin console.
//
// Replaces the UI project's own `src/views/index.vue`, which is a promotional page about the
// upstream project — its intro text, tech-stack list, changelog, QQ/WeChat groups, donation
// accounts and links to the vendor's site and repository. That page is pure credits, so it is
// swapped for this neutral welcome screen. Applied by docker/base44/ui-ptbr.mjs at startup.
//
// The route (`/index`, the console's affix home tab) and the rest of the console are untouched.

<template>
  <div class="app-container home">
    <el-card shadow="never" class="home-card">
      <h2 class="home-title">Bem-vindo ao painel administrativo</h2>
      <p class="home-text">
        Use o menu à esquerda para administrar usuários, perfis, departamentos, dicionários,
        parâmetros e demais recursos do sistema.
      </p>
    </el-card>
  </div>
</template>

<style lang="scss" scoped>
.home-card {
  max-width: 720px;
}

.home-title {
  margin: 0 0 10px;
  font-size: 20px;
  font-weight: 600;
}

.home-text {
  margin: 0;
  color: var(--el-text-color-regular);
  line-height: 1.7;
}
</style>
