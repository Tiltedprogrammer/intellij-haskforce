// This is a generated file. Not intended for manual editing.
package com.haskforce.psi.impl;

import java.util.List;
import org.jetbrains.annotations.*;
import com.intellij.lang.ASTNode;
import com.intellij.psi.PsiElement;
import com.intellij.psi.PsiElementVisitor;
import com.intellij.psi.util.PsiTreeUtil;
import static com.haskforce.psi.HaskellTypes.*;
import com.intellij.extapi.psi.ASTWrapperPsiElement;
import com.haskforce.psi.*;

public class HaskellFdeclImpl extends ASTWrapperPsiElement implements HaskellFdecl {

  public HaskellFdeclImpl(ASTNode node) {
    super(node);
  }

  public void accept(@NotNull PsiElementVisitor visitor) {
    if (visitor instanceof HaskellVisitor) ((HaskellVisitor)visitor).visitFdecl(this);
    else super.accept(visitor);
  }

  @Override
  @NotNull
  public HaskellFtype getFtype() {
    return findNotNullChildByClass(HaskellFtype.class);
  }

  @Override
  @NotNull
  public HaskellVar getVar() {
    return findNotNullChildByClass(HaskellVar.class);
  }

  @Override
  @NotNull
  public PsiElement getDoublecolon() {
    return findNotNullChildByType(DOUBLECOLON);
  }

  @Override
  @Nullable
  public PsiElement getStringtoken() {
    return findChildByType(STRINGTOKEN);
  }

}