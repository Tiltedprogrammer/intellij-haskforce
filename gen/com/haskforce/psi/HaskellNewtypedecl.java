// This is a generated file. Not intended for manual editing.
package com.haskforce.psi;

import java.util.List;
import org.jetbrains.annotations.*;
import com.intellij.psi.PsiElement;

public interface HaskellNewtypedecl extends HaskellCompositeElement {

  @Nullable
  HaskellClscontext getClscontext();

  @Nullable
  HaskellCtype getCtype();

  @Nullable
  HaskellNewconstr getNewconstr();

  @NotNull
  List<HaskellQtycls> getQtyclsList();

  @Nullable
  HaskellTycon getTycon();

  @NotNull
  List<HaskellTyvar> getTyvarList();

  @Nullable
  HaskellVarid getVarid();

  @Nullable
  PsiElement getDeriving();

  @Nullable
  PsiElement getDoublearrow();

  @Nullable
  PsiElement getEquals();

  @Nullable
  PsiElement getLparen();

  @Nullable
  PsiElement getRparen();

}
